<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<!---
 * This file combines and compresses the TinyMCE core, plugins, themes and
 * language packs into one disk cached gzipped request. It improves the loading speed of TinyMCE dramatically but
 * still provides dynamic initialization.
 --->

<!---
	/*
	 * Add any site-specific defaults here that you may wish to implement. For example:
	 *
	 * 	Variables.Settings.languages = "en";
	 *  Variables.Settings.cache_dir = expandPath("./tiny_mce_gzip_cache/");
	 *  Variables.Settings.files = "somescript,anotherscript";
	 *  Variables.Settings.expires = "1m";
	 */
 --->




<!---
	STATIC CODE
 --->

<!--- Default Settings --->
<cfparam name="Variables.Settings.cache_dir" default="#expandPath("./tiny_mce_gzip_cache/")#" type="string">
<cfparam name="Variables.Settings.compress" default="true" type="string">
<cfparam name="Variables.Settings.core" default="true" type="string">
<cfparam name="Variables.Settings.disk_cache" default="true" type="string">
<cfparam name="Variables.Settings.expires" default="30d" type="string">
<cfparam name="Variables.Settings.files" default="" type="string">
<cfparam name="Variables.Settings.js" default="true" type="string">
<cfparam name="Variables.Settings.languages" default="" type="string">
<cfparam name="Variables.Settings.max_cache" default="50" type="string">
<cfparam name="Variables.Settings.plugins" default="" type="string">
<cfparam name="Variables.Settings.source" default="false" type="string">
<cfparam name="Variables.Settings.suffix" default="" type="string">
<cfparam name="Variables.Settings.themes" default="" type="string">

<cfscript>
	// Override settings with querystring params
	// js, diskcache, core, suffix, themes, plugins, languages

	Variables.Supplied.js = getParam("js");
	if (Len(Variables.Supplied.js) GT 0)
		Variables.Settings.js = (Variables.Supplied.js EQ "true");

	Variables.Supplied.plugins = getParam("plugins");
	if (Len(Variables.Supplied.plugins) GT 0)
		Variables.Settings.plugins = Variables.Supplied.plugins;
	Variables.data.plugins = ListToArray(Variables.Settings.plugins);

	Variables.Supplied.themes = getParam("themes");
	if (Len(Variables.Supplied.themes) GT 0)
		Variables.Settings.themes = Variables.Supplied.themes;
	Variables.data.themes = ListToArray(Variables.Settings.themes);

	Variables.Supplied.languages = getParam("languages");
	if (Len(Variables.Supplied.languages) GT 0)
		Variables.Settings.languages = Variables.Supplied.languages;
	Variables.data.languages = ListToArray(Variables.Settings.languages);

	Variables.Supplied.tagFiles = getParam("files");
	if (Len(Variables.Supplied.tagFiles) GT 0)
		Variables.Settings.files = Variables.Supplied.tagFiles;
	Variables.data.files = ListToArray(Variables.Settings.files);

	Variables.Supplied.diskCache = getParam("diskcache");
	if (Len(Variables.Supplied.diskCache) GT 0)
		Variables.Settings.disk_cache = (Variables.Supplied.diskCache EQ "true");

	Variables.Supplied.src = getParam("src");
	if (Len(Variables.Supplied.src) GT 0)
		Variables.Settings.source = (Variables.Supplied.src EQ "true");
</cfscript>

<cfset Variables.expiresOffset = parseTime(Variables.Settings.Expires)>
<cfset Variables.save_cache = false>
<cfset Variables.SupportsGzip = false>
<cfset Variables.LoadedFromBase = Reverse(ListRest(Reverse(CGI.SCRIPT_NAME), "/"))>

<!--- Shall we GZIP? --->
<cfset Variables.encodings = LCase(CGI.HTTP_ACCEPT_ENCODING)>
<cfif ListFind(Variables.encodings, "gzip") GT 0>
	<cfset Variables.encoding = "gzip">
<cfelseif ListFind(Variables.encodings, "x-gzip") GT 0>
	<cfset Variables.encoding = "x-gzip">
<cfelse>
	<cfset Variables.encoding = "">
</cfif>

<!--- Is northon antivirus header --->
<cfif StructKeyExists(CGI, "---------------")>
	<cfset Variables.encoding = "x-gzip">
</cfif>

<cfset Variables.supportsGzip = Variables.Settings.compress AND Len(Variables.encoding) GT 0>

<!--- UTC time --->
<cfset Variables.NowUTC = DateConvert("local2Utc", now())>
<cfset Variables.ExpiresDate = dateAdd('s', Variables.expiresOffset, Variables.NowUTC)>

<!--- HEADERS --->
<cfheader name="Content-type" value="text/javascript">
<cfheader name="Vary" value="Accept-Encoding">  <!--- HANDLE PROXIES --->
<cfheader name="Expires" value="#dateFormat(Variables.ExpiresDate, "dddd, dd mmm yyyy")# #timeFormat(Variables.ExpiresDate, "hh:mm:ss")# GMT">
<cfheader name="Cache-Control" value="public, max-age=#Variables.expiresOffset#">
<cfif Variables.supportsGzip EQ true>
	<cfheader name="Content-Encoding" value="#Variables.encoding#">
</cfif>

<!--- IF CALLED DIRECTLY THEN AUTO INIT WITH DEFAULT SETTINGS --->
<cfif Variables.Settings.js EQ false>
	<cfoutput>#getFileContents(expandpath("tiny_mce_gzip.js"))# tinyMCE_GZ.init({});</cfoutput>
	<cfabort>
</cfif>

<!---
  --- Get full list of files
  --->
<cfset Variables.aScripts = ArrayNew(1)>

<!--- ADD CORE LANGUAGES --->
<cfloop from="1" to="#arrayLen(Variables.data.languages)#" index="CurrentIndex">
	<cfset ArrayAppend(Variables.aScripts,  "langs/" & Variables.data.languages[CurrentIndex])>
</cfloop>

<!--- ADD THEMES --->
<cfloop from="1" to="#arrayLen(Variables.data.themes)#" index="CurrentIndex">
	<cfset ArrayAppend(Variables.aScripts,  "themes/" & Variables.data.themes[CurrentIndex] & "/editor_template" & Variables.Settings.suffix)>

	<cfloop from="1" to="#arrayLen(Variables.data.languages)#" index="CurrentSubIndex">
		<cfset ArrayAppend(Variables.aScripts,  "themes/" & Variables.data.themes[CurrentIndex] & "/langs/" & Variables.data.languages[CurrentSubIndex])>
	</cfloop>
</cfloop>

<!--- ADD PLUGINS --->
<cfloop from="1" to="#arrayLen(Variables.data.plugins)#" index="CurrentIndex">
	<cfset ArrayAppend(Variables.aScripts,  "plugins/" & Variables.data.plugins[CurrentIndex] & "/editor_plugin" & Variables.Settings.suffix)>

	<cfloop from="1" to="#arrayLen(Variables.data.languages)#" index="CurrentSubIndex">
		<cfset ArrayAppend(Variables.aScripts,  "plugins/" & Variables.data.plugins[CurrentIndex] & "/langs/" & Variables.data.languages[CurrentSubIndex])>
	</cfloop>
</cfloop>

<!--- Sort array to elimiate duplicates casused by varying order --->
<cfset ArraySort(Variables.aScripts, "textnocase")>

<!--- ADD CORE - Must always be fist --->
<cfif Variables.Settings.core EQ true>
	<cfset ArrayPrepend(Variables.aScripts,  "tiny_mce" & Variables.Settings.suffix)>
</cfif>

<!--- ADD CUSTOM FILES - Should be in the order specified in the config --->
<cfloop from="1" to="#arrayLen(Variables.data.files)#" index="CurrentIndex">
	<cfset ArrayAppend(Variables.aScripts,  Variables.data.files[CurrentIndex])>
</cfloop>


<!--- Correct the extensions --->
<cfset Variables.ThisDirectory = ExpandPath("./")>
<cfloop from="1" to="#arrayLen(Variables.aScripts)#" index="CurrentIndex">
	<cfset Variables.ThisFile = Variables.aScripts[Variables.CurrentIndex]>

	<cfif Variables.Settings.Source AND FileExists(Variables.ThisDirectory & Variables.ThisFile & "_src.js")>
		<cfset Variables.ThisFile = Variables.ThisFile & "_src.js">
	<cfelseif FileExists(Variables.ThisDirectory & Variables.ThisFile & ".js")>
		<cfset Variables.ThisFile = Variables.ThisFile & ".js">
	<cfelse>
		<cfset Variables.ThisFile = "">
	</cfif>

	<cfset Variables.aScripts[Variables.CurrentIndex] = Variables.ThisFile>
</cfloop>

<cfset Variables.ScriptList = ArrayToList(Variables.aScripts)>


<!---
  --- Cache related
  --->
<cfif Variables.Settings.disk_cache EQ true>

	<!--- MAKE SURE THE CACHE DIR EXISTS --->
	<cfif directoryExists(Variables.Settings.cache_dir) EQ false>
		<cfdirectory action="create" directory="#Variables.Settings.cache_dir#">
	</cfif>

	<!--- Get cache count --->
	<cfdirectory action="list" directory="#Variables.Settings.cache_dir#" name="qryFiles" listinfo="name" recurse="false" type="file">

	<!---
		// Only put file in cache if the number of cached files is less
		// than the set max files this will reduce a possible DOS attack
	 --->
	 <cfif qryFiles.RecordCount LT Variables.Settings.max_cache>
		<cfset Variables.save_cache = true>
	 </cfif>

</cfif>

<!---
  --- SETUP CACHE INFO - Used for locking as well as cache
  --->
<cfset Variables.cacheKey = hash(Variables.ScriptList & Variables.Settings.suffix & '@' & Variables.LoadedFromBase, "md5")>

<cfset Variables.fileBase = Variables.Settings.cache_dir & Variables.cacheKey>
<cfset Variables.fileJS = Variables.fileBase & ".js">
<cfset Variables.fileGZ = Variables.fileJS & ".gz">
<cfset Variables.lockJS = "JS" & Hash(Variables.fileJS, "SHA")>
<cfset Variables.lockGZ = "GZ" & Hash(Variables.fileGZ, "SHA")>

<!--- Get JS content --->
<cflock name="#Variables.lockJS#" type="readonly" timeout="4">
	<cfif Variables.Settings.disk_cache EQ true AND fileExists(Variables.fileJS) EQ true>
		<cfset Variables.contentJS = getFileContents(Variables.fileJS)>
	<cfelse>

		<!--- // Set base URL for where tinymce is loaded from --->
		<cfset Variables.contentJS = "var tinyMCEPreInit={base:'" & Variables.LoadedFromBase & "',suffix:''};">

		<!--- Get file contents --->
		<cfloop from="1" to="#arrayLen(Variables.aScripts)#" index="CurrentIndex">
			<cfset Variables.contentJS = Variables.contentJS & getFileContents(Variables.ThisDirectory & Variables.aScripts[CurrentIndex])>
		</cfloop>

		<!--- // Mark all themes, plugins and languages as done --->
		<cfset Variables.contentJS = Variables.contentJS & 'tinymce.each("' & Variables.ScriptList & '".split(","),function(f){tinymce.ScriptLoader.markDone(tinyMCE.baseURL+"/"+f+".js");});'>

	</cfif>
</cflock>

<!--- Save JS content --->
<cfif Variables.save_cache EQ true AND fileExists(Variables.fileJS) EQ false>
	<cflock name="#Variables.lockJS#" type="exclusive" timeout="4">
		<cfset saveFile(file=Variables.fileJS, content=Variables.contentJS)>
	</cflock>
</cfif>


<cfif Variables.supportsGzip EQ true>
	<!--- Get GZ content --->
	<cflock name="#Variables.lockGZ#" type="readonly" timeout="4">
		<cfif Variables.Settings.disk_cache EQ true AND fileExists(Variables.fileGZ) EQ true>
			<cfset Variables.contentGZ = getFileContentsBinary(Variables.fileGZ)>
		<cfelse>
			<cfset Variables.contentGZ = makeGZ(content=Variables.contentJS)>
		</cfif>
	</cflock>

	<!--- Save GZ content --->
	<cfif Variables.save_cache EQ true AND fileExists(Variables.fileGZ) EQ false>
		<cflock name="#Variables.lockGZ#" type="exclusive" timeout="4">
			<cfset saveFileBinary(file=Variables.fileGZ, content=Variables.contentGZ)>
		</cflock>
	</cfif>
</cfif>

<!--- Serve the content --->
<cfif Variables.supportsGzip EQ false>
	<cfset serveContent(content=ToBinary(ToBase64(Variables.contentJS)))>
<cfelse>
	<cfset serveContent(content=Variables.contentGZ)>
</cfif>



<!---
	Functions
 --->

<cffunction name="makeGZ" output="false" hint="Returns content gziped.">
	<cfargument name="content" required="true" >

	<cfscript>

		/* Create Objects */
		var ioOutput = CreateObject("java","java.io.ByteArrayOutputStream");
		var gzOutput = CreateObject("java","java.util.zip.GZIPOutputStream");

		ioOutput.init();
		gzOutput.init(ioOutput);

		gzOutput.write(content.getBytes(), 0, Len(content.getBytes()));

		gzOutput.finish();
		gzOutput.close();
		ioOutput.flush();
		ioOutput.close();
	</cfscript>

	<cfreturn ioOutput.toByteArray()>

</cffunction>


<cffunction name="serveContent" output="false">
	<cfargument name="content" required="true" type="binary">

	<cfcontent variable="#arguments.content#">
</cffunction>


<cffunction name="saveFile" output="false" returntype="void">
	<cfargument name="file" required="true">
	<cfargument name="content" required="true">

	<cffile action="write" output="#Arguments.content#" charset="iso-8859-1" file="#arguments.file#" >
</cffunction>

<cffunction name="saveFileBinary" output="false" returntype="void">
	<cfargument name="file" required="true">
	<cfargument name="content" required="true">

	<cffile action="write" output="#Arguments.content#" file="#arguments.file#" >
</cffunction>


<cffunction name="deleteFile" output="false" returntype="void" hint="deletes a file.">
	<cfargument name="file" required="true" >

	<cftry>
		<cffile action="delete" file="#arguments.file#">
		<cfcatch></cfcatch>
	</cftry>
</cffunction>


<cffunction name="getFileContents" output="false" returntype="string" hint="Gets the contents of a file">
	<cfargument name="path">

	<cfset var content = "">

	<cftry>
		<cffile action="read" file="#arguments.path#" variable="content">

		<cfcatch></cfcatch>
	</cftry>

	<cfreturn content>
</cffunction>

<cffunction name="getFileContentsBinary" output="false" returntype="binary" hint="Gets the contents of a file">
	<cfargument name="path">

	<cfset var content = "">

	<cftry>
		<cffile action="readbinary" file="#arguments.path#" variable="content">

		<cfcatch></cfcatch>
	</cftry>

	<cfreturn content>
</cffunction>

<!---
	/**
	 * Returns a sanitized query string parameter.
	 *
	 * @param String $name Name of the query string param to get.
	 * @param String $default Default value if the query string item shouldn't exist.
	 * @return String Sanitized query string parameter value.
	 */
 --->
<cffunction name="getParam" output="false" returntype="string" hint="Returns a sanitized query string parameter.">
	<cfargument name="name" required="true">
	<cfargument name="default" required="false" default="">

	<cfscript>
		var result = Arguments.default;

		if (StructKeyExists(URL, Arguments.Name) EQ true) {
			result = REReplaceNoCase(URL[Arguments.Name], "[^0-9a-z\-_,]+", "", "ALL");  // Sanatize for security, remove anything but 0-9,a-z,-_,
		}
	</cfscript>

	<cfreturn result>
</cffunction>

<!---
	/**
	 * Parses the specified time format into seconds. Supports formats like 10h, 10d, 10m.
	 *
	 * @param String $time Time format to convert into seconds.
	 * @return Int Number of seconds for the specified format.
	 */
--->
<cffunction name="parseTime" output="false" returntype="numeric" hint="Parses the specified time format into seconds.">
	<cfargument name="time" required="true">

	<cfscript>
		var multipel = 1;
		var result = 0;

		// Hours
		if (Find(Arguments.time, "h") > 0)
			multipel = 3600;

		// Days
		if (Find(Arguments.time, "d") > 0)
			multipel = 86400;

		// Months
		if (Find(Arguments.time, "m") > 0)
			multipel = 2592000;

		// Trim string
		result = int(val(Arguments.time)) * multipel;
	</cfscript>

	<cfreturn result>

</cffunction>