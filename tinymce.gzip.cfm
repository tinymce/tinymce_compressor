<!---
//  This file compresses the TinyMCE JavaScript using GZip and enables
//  the browser to do two requests instead of one for each .js file.
//  Notice: This script defaults the button_tile_map option to true
//  for extra performance.
--->

<cfsavecontent variable="credits">
//  --------------------------------------------------------------------
//  This file was concatenated (and most likely also cached and gzipped)
//  by TinyMCE CF GZIP, a ColdFusion based Javascript Concatenater,
//  Compressor, and Cacher for TinyMCE.
//  V1, Mon Feb 9 9:00:00 -0500 2009
//  
//  Copyright (c) 2009 Jules Gravinese (http://www.webveteran.com/)
//  
//  TinyMCE CF GZIP is licensed under LGPL license.
//  More details can be found here: http://tinymce.moxiecode.com/license.php
//  
//  The gzip functions were adapted and incorporated by permission
//  from Artur Kordowski's Zip CFC 1.2 : http://zipcfc.riaforge.org/
//</cfsavecontent>
 
<!--- HEADERS --->
<cfheader name="Content-type" value="text/javascript">
<cfheader name="Vary" value="Accept-Encoding">  <!--- HANDLE PROXIES --->
<cfheader name="Expires" value="#dateFormat(dateAdd('d', 7, now()), "dddd, dd mmm yyyy")# #timeFormat(now(), "hh:mm:ss")# GMT">

<!--- DEFAULT INPUTS --->
<cfparam name="url.diskCache" default="true">
<cfparam name="url.js" default="true">
<cfparam name="url.compress" default="true">
<cfparam name="url.core" default="true">
<cfparam name="url.suffix" default="">

<!--- GET INPUTS --->
<cfset plugins = listToArray(url.plugins)>
<cfset languages = listToArray(url.languages)>
<cfset themes = listToArray(url.themes)>
<cfset diskCache = url.diskcache>
<cfset isJS = url.js>
<cfset compress = url.compress>
<cfset core = url.core>
<cfset suffix = url.suffix>
<cfset cachePath = expandPath(".\tiny_mce_gzip_cache\")>
<cfset expiresOffset = createTimeSpan(10,0,0,0)> <!--- Cache for 10 days in browser cache --->
<cfset content = "">
<cfset encodings = arrayNew(2)>
<cfset supportsGzip = false>
<cfset enc = "">
<cfset cacheKey = "">

<!--- COMPRESS OVERRIDE --->
<cfif cgi.HTTP_ACCEPT_ENCODING does not contain "gzip">
	<cfset compress = 0>
</cfif>

<!--- CUSTOM EXTRA JAVASCRIPTS TO PACK --->
<cfset custom = arrayNew(2)>
<!---
<cfset custom[1] = "some custom .js file">
<cfset custom[2] = "some custom .js file">
--->

<!--- IF CALLED DIRECTLY THEN AUTO INIT WITH DEFAULT SETTINGS --->
<cfif isJS eq 0>
	<cfoutput>#getFileContents("tiny_mce_gzip.js")# tinyMCE_GZ.init({});</cfoutput>
	<cfabort>
</cfif>

<!--- MAKE SURE THE CACHE DIR EXISTS --->
<!--- WE ALSO USE IT FOR THE TEMP JS->GZ OPERATION --->
<cfif not directoryExists(cachePath)>
	<cfdirectory action="create" directory="#cachePath#">
</cfif>

<!--- SETUP CACHE INFO --->
<cfif diskCache eq 1>
	<cfset cacheKey = cacheKey & url.plugins & url.languages & url.themes & suffix>	
	<cfloop from="1" to="#arrayLen(custom)#" index="a">
		<cfset cacheKey = cacheKey & custom[a]>
	</cfloop>
	<cfset cacheKey = hash(cacheKey, "md5")>
	<cfset fileBase = cachePath & cacheKey>
	<cfset fileJS = fileBase & ".js">	
	<cfif compress eq 1>
		<cfset fileGZ = fileJS & ".gz">
		<cfif not fileExists(fileGZ)>
			<cfset makeJS(file=fileJS)>
			<cfset makeGZ(fileJS=fileJS)>
		</cfif>
		<cfset serveGZ(file=fileGZ)>
	<cfelse>
		<cfif not fileExists(fileJS)>
			<cfset makeJS(file=fileJS)>
		</cfif>
		<cfset serveJS(file=fileJS)>
	</cfif>
<cfelse>
	<cfset fileBase = cachePath>
	<cfset fileJS = fileBase & "temp.js">
	<cfset makeJS(file=fileJS)>
	<cfif compress eq 1>
		<cfset fileGZ = fileBase & "temp.js.gz">
		<cfset makeGZ(fileJS=fileJS)>
		<!--- CANNOT DO MORE WORK AFTER CFCONTENT, SO DELETE THE TEMP JS NOW --->
		<cfset del = deleteFile(file=fileJS)>
		<cfset serveGZ(file=fileGZ, delete=1)>
	<cfelse>
		<cfset serveJS(file=fileJS, delete=1)>
	</cfif>
</cfif>


<cffunction name="makeJS">
	<cfargument name="file" required="true" >
	
	<!--- ADD CORE --->
	<cfif core eq true>
		<cfset content = content & getFileContents("tiny_mce" & suffix & ".js")>
	
		<!--- PATCH LOADING FUNCTIONS --->
		<cfset content = content & "tinyMCE_GZ.start();">
	</cfif>
	
	<!--- ADD CORE LANGUAGES --->
	<cfloop from="1" to="#arrayLen(languages)#" index="l">
		<cfset content = content & getFileContents("langs/" & languages[l] & ".js")>
	</cfloop>
	
	<!--- ADD THEMES --->
	<cfloop from="1" to="#arrayLen(themes)#" index="t">
		<cfset content = content & getFileContents( "themes/" & themes[t] & "/theme" & suffix & ".js")>
	
		<cfloop from="1" to="#arrayLen(languages)#" index="l">
			<cfset content = content & getFileContents("themes/" & themes[t] & "/langs/" & languages[l] & ".js")>
		</cfloop>
	</cfloop>
	
	<!--- ADD PLUGINS --->
	<cfloop from="1" to="#arrayLen(plugins)#" index="p">
		<cfset content = content & getFileContents("plugins/" & plugins[p] & "/plugin" & suffix & ".js")>
	
		<cfloop from="1" to="#arrayLen(languages)#" index="l">
			<cfset content = content & getFileContents("plugins/" & plugins[p] & "/langs/" & languages[l] & ".js")>
		</cfloop>
	</cfloop>
	
	<!--- ADD CUSTOM FILES --->
	<cfloop from="1" to="#arrayLen(custom)#" index="c">
		<cfset content = content & getFileContents(custom[c])>
	</cfloop>
	
	<!--- RESTORE LOADING FUNCTIONS --->
	<cfif core eq true>
		<cfset content = content & "tinyMCE_GZ.end();">
	</cfif>
	
<!--- HOW BIG IS THE UNCOMPRESSED JS? --->
<cfsavecontent variable="heading"><cfoutput>
#credits#
//  This uncompressed concatenated JS: #numberformat((content.length() + credits.length())/1024, .00)# KB
//  --------------------------------------------------------------------

</cfoutput></cfsavecontent>
	<cfset content = heading & content>
	
	<!--- WRITE THE JS FILE --->
	<cffile action="write" output="#content#" charset="ISO-8859-1" file="#arguments.file#">
</cffunction>


<cffunction name="serveJS">
	<cfargument name="file" required="true" >
	<cfargument name="delete" default="0" >
	
	<cfcontent file="#arguments.file#" deleteFile="#arguments.delete#" type="text/javascript; charset=ISO-8859-1">
</cffunction>


<cffunction name="makeGZ">
	<cfargument name="fileJS" required="true" >
	
	<cfscript>

		/* Create Objects */
		ioInput     = CreateObject("java","java.io.FileInputStream");
		ioOutput    = CreateObject("java","java.io.FileOutputStream");
		gzOutput    = CreateObject("java","java.util.zip.GZIPOutputStream");

		/* Set Variables */
		this.os = Server.OS.Name;

		if(FindNoCase("Windows", this.os)) this.slash = "\";
		else                               this.slash = "/";

		/* Default variables */
		l = 0;
		buffer     = RepeatString(" ",1024).getBytes();
		gzFileName = "";
		outputFile = "";

		/* Convert to the right path format */
		arguments.gzipFilePath = PathFormat(cachePath);
		arguments.filePath     = PathFormat(arguments.fileJS);

		/* Check if the 'extractPath' string is closed */
		lastChr = Right(arguments.gzipFilePath, 1);

		/* Set an slash at the end of string */
		if(lastChr NEQ this.slash)
			arguments.gzipFilePath = arguments.gzipFilePath & this.slash;

		try
		{

			/* Set output gzip file name */
			gzFileName = getFileFromPath(arguments.filePath) & ".gz";
			outputFile = arguments.gzipFilePath & gzFileName;

			ioInput.init(arguments.filePath);
			ioOutput.init(outputFile);
			gzOutput.init(ioOutput);

			l = ioInput.read(buffer);
			
			while(l GT 0)
			{
				gzOutput.write(buffer, 0, l);
				l = ioInput.read(buffer);
			}

			/* Close the GZip file */
			gzOutput.close();
			ioOutput.close();
			ioInput.close();

			/* Return true */
			return true;
		}

		catch(Any expr)
		{ return false; }

	</cfscript>

</cffunction>


<cffunction name="PathFormat" access="private" output="no" returntype="string" hint="Convert path into Windows or Unix format.">
	<cfargument name="path" required="yes" type="string" hint="The path to convert.">

	<cfif FindNoCase("Windows", this.os)>
		<cfset arguments.path = Replace(arguments.path, "/", "\", "ALL")>
	<cfelse>
		<cfset arguments.path = Replace(arguments.path, "\", "/", "ALL")>
	</cfif>

	<cfreturn arguments.path>
</cffunction>


<cffunction name="serveGZ">
	<cfargument name="file" required="true" >
	<cfargument name="delete" default="0" >
	
	<cfheader name="Content-Encoding" value="gzip">
	<cfcontent file="#arguments.file#" deleteFile="#arguments.delete#" type="text/javascript; charset=ISO-8859-1">
</cffunction>


<cffunction name="deleteFile">
	<cfargument name="file" required="true" >
	
	<cftry>
		<cffile action="delete" file="#arguments.file#">
		<cfcatch></cfcatch>
	</cftry>
</cffunction>


<cffunction name="getFileContents">
	<cfargument name="path">
	
	<cfif not directoryExists(expandPath("#arguments.path#")) AND not fileExists(expandPath("#arguments.path#"))>
		<cfreturn "">
	</cfif>
	
	<cffile action="read" file="#expandpath('#arguments.path#')#" variable="content">
	<cfreturn content>
</cffunction>