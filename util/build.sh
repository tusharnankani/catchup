#!/bin/bash

set -eu;

script_dir=$(dirname "${0}");

echo "Building summary pages using Asciidoctor Jet...";

# Create required directories if they don't exist
mkdir -p "${script_dir}/../public/css/summary";
mkdir -p "${script_dir}/../public/html/summary";
mkdir -p "${script_dir}/../public/js/summary";
mkdir -p "${script_dir}/../public/img/summary";

# Remove all summary files to prevent residual files
rm -rf "${script_dir}/../public/css/summary/"*;
rm -rf "${script_dir}/../public/html/summary/"*;
rm -rf "${script_dir}/../public/js/summary/"*;
rm -rf "${script_dir}/../public/img/summary/"*;
rm -f "${script_dir}/../summary/autogenerated-combined-summary.adoc";

# Copy files to public directory for static serving
cp -r "${script_dir}/../summary/static/css/"* "${script_dir}/../public/css/summary";
cp -r "${script_dir}/../summary/static/js/"* "${script_dir}/../public/js/summary";
cp -r "${script_dir}/../summary/static/img/"* "${script_dir}/../public/img/summary";

# Reverse order so summaries are newest to oldest
BUILD_SUMMARY_DIRS="";
for path in "${script_dir}/../summary/sessions/"*; do
	if [ -d "${path}" ]; then
		BUILD_SUMMARY_DIRS="${path} ${BUILD_SUMMARY_DIRS}";
	fi;
done;

# Build individual summary pages
for path in ${BUILD_SUMMARY_DIRS}; do
	if [ -d "${path}" ]; then
		catchup_number=${path##*/};
		printf -v "catchup_display_number" "%.0f" "${catchup_number}";

		# Add to combined summary page
		# if summary/sessions/${catchup_number}/combined-summary.adoc exists,
		# then use it, else use the default template
		combined_summary_template="${script_dir}/../summary/sessions/${catchup_number}/combined-summary.adoc";
		if [ ! -f combined_summary_template ]; then
			combined_summary_template="${script_dir}/../summary/combined-summary-template.adoc";
		fi;
		sed \
			-e "s/{catchup_number}/${catchup_number}/g" \
			-e "s/{catchup_display_number}/${catchup_display_number}/g" \
			"${combined_summary_template}" \
		>> "${script_dir}/../summary/autogenerated-combined-summary.adoc";

		asciidoctor \
			-a webfonts! \
			-a "catchup_number=${catchup_number}" \
			-a "catchup_display_number=${catchup_display_number}" \
			-o "${script_dir}/../public/html/summary/${catchup_number}.html" \
			"${script_dir}/../summary/individual-summary.adoc";

		# Lazy load images
		sed -i -e "s/<img/<img loading=\"lazy\"/g" "${script_dir}/../public/html/summary/${catchup_number}.html";
	fi;
done;

# Build combined summary site
asciidoctor \
	-a webfonts! \
	-o "${script_dir}/../public/html/summary/combined-summary.html" \
	"${script_dir}/../summary/combined-summary.adoc";
# Lazy load images
sed -i -e 's/<img/<img loading="lazy"/g' "${script_dir}/../public/html/summary/combined-summary.html";

echo -e "Summary pages build complete!\n";
