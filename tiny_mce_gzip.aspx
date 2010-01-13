<%@ Page Language="C#" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="ICSharpCode.SharpZipLib.GZip" %>
<%
/**
 * $Id: tiny_mce_gzip.aspx 316 2007-10-25 14:50:55Z spocke $
 *
 * @author Moxiecode
 * @copyright Copyright © 2006, Moxiecode Systems AB, All rights reserved.
 *
 * This file compresses the TinyMCE JavaScript using GZip and
 * enables the browser to do two requests instead of one for each .js file.
 *
 * It's a good idea to use the diskcache option since it reduces the servers workload.
 */

	string cacheKey = "", cacheFile = "", content = "", enc, suffix, cachePath;
	string[] plugins, languages, themes;
	bool diskCache, supportsGzip, isJS, compress, core;
	int i, x, bytes, expiresOffset;
	GZipOutputStream gzipStream;
	Encoding encoding = Encoding.GetEncoding("windows-1252");
	byte[] buff;

	// Get input
	plugins = GetParam("plugins", "").Split(',');
	languages = GetParam("languages", "").Split(',');
	themes = GetParam("themes", "").Split(',');
	diskCache = GetParam("diskcache", "") == "true";
	isJS = GetParam("js", "") == "true";
	compress = GetParam("compress", "true") == "true";
	core = GetParam("core", "true") == "true";
	suffix = GetParam("suffix", "") == "_src" ? "_src" : "";
	cachePath = Server.MapPath("."); // Cache path, this is where the .gz files will be stored
	expiresOffset = 10; // Cache for 10 days in browser cache

	// Custom extra javascripts to pack
	string[] custom = {/*
		"some custom .js file",
		"some custom .js file"
	*/};

	// Set response headers
	Response.ContentType = "text/javascript";
	Response.Charset = "UTF-8";
	Response.Buffer = false;

	// Setup cache
	Response.Cache.SetExpires(DateTime.Now.AddDays(expiresOffset));
	Response.Cache.SetCacheability(HttpCacheability.Public);
	Response.Cache.SetValidUntilExpires(false);

	// Vary by all parameters and some headers
	Response.Cache.VaryByHeaders["Accept-Encoding"] = true;
	Response.Cache.VaryByParams["theme"] = true;
	Response.Cache.VaryByParams["language"] = true;
	Response.Cache.VaryByParams["plugins"] = true;
	Response.Cache.VaryByParams["lang"] = true;
	Response.Cache.VaryByParams["index"] = true;

	// Is called directly then auto init with default settings
	if (!isJS) {
		Response.WriteFile(Server.MapPath("tiny_mce_gzip.js"));
		Response.Write("tinyMCE_GZ.init({});");
		return;
	}

	// Setup cache info
	if (diskCache) {
		cacheKey = GetParam("plugins", "") + GetParam("languages", "") + GetParam("themes", "");

		for (i=0; i<custom.Length; i++)
			cacheKey += custom[i];

		cacheKey = MD5(cacheKey);

		if (compress)
			cacheFile = cachePath + "/tiny_mce_" + cacheKey + ".gz";
		else
			cacheFile = cachePath + "/tiny_mce_" + cacheKey + ".js";
	}

	// Check if it supports gzip
	enc = Regex.Replace("" + Request.Headers["Accept-Encoding"], @"\s+", "").ToLower();
	supportsGzip = enc.IndexOf("gzip") != -1 || Request.Headers["---------------"] != null;
	enc = enc.IndexOf("x-gzip") != -1 ? "x-gzip" : "gzip";

	// Use cached file disk cache
	if (diskCache && supportsGzip && File.Exists(cacheFile)) {
		Response.AppendHeader("Content-Encoding", enc);
		Response.WriteFile(cacheFile);
		return;
	}

	// Add core
	if (core) {
		content += GetFileContents("tiny_mce" + suffix + ".js");

		// Patch loading functions
		content += "tinyMCE_GZ.start();";
	}

	// Add core languages
	for (x=0; x<languages.Length; x++)
		content += GetFileContents("langs/" + languages[x] + ".js");

	// Add themes
	for (i=0; i<themes.Length; i++) {
		content += GetFileContents("themes/" + themes[i] + "/editor_template" + suffix + ".js");

		for (x=0; x<languages.Length; x++)
			content += GetFileContents("themes/" + themes[i] + "/langs/" + languages[x] + ".js");
	}

	// Add plugins
	for (i=0; i<plugins.Length; i++) {
		content += GetFileContents("plugins/" + plugins[i] + "/editor_plugin" + suffix + ".js");

		for (x=0; x<languages.Length; x++)
			content += GetFileContents("plugins/" + plugins[i] + "/langs/" + languages[x] + ".js");
	}

	// Add custom files
	for (i=0; i<custom.Length; i++)
		content += GetFileContents(custom[i]);

	// Restore loading functions
	if (core)
		content += "tinyMCE_GZ.end();";

	// Generate GZIP'd content
	if (supportsGzip) {
		if (compress)
			Response.AppendHeader("Content-Encoding", enc);

		if (diskCache && cacheKey != "") {
			// Gzip compress
			if (compress) {
				gzipStream = new GZipOutputStream(File.Create(cacheFile));
				buff = encoding.GetBytes(content.ToCharArray());
				gzipStream.Write(buff, 0, buff.Length);
				gzipStream.Close();
			} else {
				StreamWriter sw = File.CreateText(cacheFile);
				sw.Write(content);
				sw.Close();
			}

			// Write to stream
			Response.WriteFile(cacheFile);
		} else {
			gzipStream = new GZipOutputStream(Response.OutputStream);
			buff = encoding.GetBytes(content.ToCharArray());
			gzipStream.Write(buff, 0, buff.Length);
			gzipStream.Close();
		}
	} else
		Response.Write(content);
%><script runat="server">
	public string GetParam(string name, string def) {
		string value = Request.QueryString[name] != null ? "" + Request.QueryString[name] : def;

		return Regex.Replace(value, @"[^0-9a-zA-Z\\-_,]+", "");
	}

	public string GetFileContents(string path) {
		try {
			string content;

			path = Server.MapPath(path);

			if (!File.Exists(path))
				return "";

			StreamReader sr = new StreamReader(path);
			content = sr.ReadToEnd();
			sr.Close();

			return content;
		} catch (Exception ex) {
			// Ignore any errors
		}

		return "";
	}

	public string MD5(string str) {
		MD5 md5 = new MD5CryptoServiceProvider();
		byte[] result = md5.ComputeHash(Encoding.ASCII.GetBytes(str));
		str = BitConverter.ToString(result);

		return str.Replace("-", "");
	}
</script>