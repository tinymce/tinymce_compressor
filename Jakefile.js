var zip = require('./tools/BuildTools').zip;
var getReleaseDetails = require('./tools/BuildTools').getReleaseDetails;
var fs = require("fs");
var UglifyJS = require("uglify-js");

desc("Default build task");
task("default", ["release"], function () {});

task("release", [], function () {
	var details = getReleaseDetails("changelog_php.txt");

	if (!fs.existsSync("tmp")) {
		fs.mkdirSync("tmp");
	}

	function createPackage(page, suffix) {
		zip({
			baseDir: "tinymce_compressor",

			from: [
				"tinymce.gzip.js",
				page,
				["tools/readme.installation.txt", "readme.txt"]
			],

			dataFilter: function(args) {
				if (args.zipFilePath == 'tinymce.gzip.js') {
					var source = args.data.toString().replace(/tinymce\.gzip\.php/g, page);

					var ast = UglifyJS.parse(source);
					ast.figure_out_scope();
					ast = ast.transform(UglifyJS.Compressor());
					ast.figure_out_scope();
					ast.compute_char_frequency();
					ast.mangle_names();

					var stream = UglifyJS.OutputStream();
					ast.print(stream);

					args.data = stream.toString();
				}
			},

			to: "tmp/tinymce_compressor_" + details.version + "_" + suffix + ".zip"
		});
	}

	createPackage("tinymce.gzip.php", "php");
	createPackage("tinymce.gzip.ashx", "net");
	createPackage("tinymce.gzip.jsp", "jsp");
	createPackage("tinymce.gzip.cfm", "cfm");
	createPackage("tinymce.gzip.pl", "perl");
});
