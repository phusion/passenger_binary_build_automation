#!/usr/bin/env bash

ROOTDIR=$(dirname "$0")

shopt -s lastpipe

if [ -n "$GITHUB_API_TOKEN" ]; then
TOKEN="$GITHUB_API_TOKEN"
else
read -p "Enter Your GitHub Token: " TOKEN
echo
fi

write_version() {
	read file version
	echo "$version" > "$ROOTDIR/shared/definitions/$file"
}

getLatest() {
	curl -H "Authorization: token $TOKEN" --silent "https://api.github.com/repos/$1/releases/latest" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["tag_name"].delete_prefix("v").gsub("_",".").delete_prefix("curl-")'
}

getLatestTag() {
	PAGES=$(curl -H "Authorization: token $TOKEN" -I --silent "https://api.github.com/repos/$1/tags" | grep -ie '^Link:' | awk -F, '{print $2}' | sed -Ee 's/.*<(.*)>.*/\1/g' | awk -F= '{print $2}')
	for PAGE in $(seq 1 "${PAGES:-1}"); do curl -H "Authorization: token $TOKEN" --silent "https://api.github.com/repos/$1/tags?page=$PAGE"; done | ruby -rjson -e 'puts JSON.parse(STDIN.read.gsub(/\][\n]*\[/,",")).map{|e|e["name"]}.reject{|e|["rc","gitgui","fips","levitte","-engine-","beta","ssleay","master","before","after","pre","post","rsaref","alpha","1000","bundler-","dist-"].any?{|s|e.downcase.include?(s)}}.map{|s|s.delete_prefix("v").delete_prefix("OpenSSL_").delete_prefix("openssl-").delete_prefix("pcre2-").gsub("_",".")}' | grep -e '[0-9]' | sort -V | tail -1
}

if [ "${RESTRICT:-cmake}" = "cmake" ]; then
	echo starting cmake…
	getLatestTag Kitware/CMake > "$ROOTDIR/shared/definitions/cmake_version"
else
	echo skipping cmake…
fi
if [ "${RESTRICT:-ccache}" = "ccache" ]; then
	echo starting ccache…
	getLatest ccache/ccache > "$ROOTDIR/shared/definitions/ccache_version"
else
	echo skipping ccache…
fi
if [ "${RESTRICT:-curl}" = "curl" ]; then
	echo starting curl…
	getLatest curl/curl     > "$ROOTDIR/shared/definitions/curl_version"
else
	echo skipping curl…
fi
if [ "${RESTRICT:-libpsl}" = "libpsl" ]; then
	echo starting libpsl…
	getLatest rockdaboot/libpsl > "$ROOTDIR/shared/definitions/libpsl_version"
else
	echo skipping libpsl…
fi
if [ "${RESTRICT:-geoip}" = "geoip" ]; then
	echo starting geoip…
	getLatest maxmind/geoip-api-c > "$ROOTDIR/shared/definitions/geoip_version"
else
	echo skipping geoip…
fi
if [ "${RESTRICT:-s3cmd}" = "s3cmd" ]; then
	echo starting s3cmd…
	getLatest s3tools/s3cmd > "$ROOTDIR/shared/definitions/s3cmd_version"
else
	echo skipping s3cmd…
fi
if [ "${RESTRICT:-zstd}" = "zstd" ]; then
	echo starting zstd…
	getLatest facebook/zstd > "$ROOTDIR/shared/definitions/zstd_version"
else
	echo skipping zstd…
fi
if [ "${RESTRICT:-rubygems}" = "rubygems" ]; then
	echo starting rubygems…
	getLatestTag rubygems/rubygems > "$ROOTDIR/shared/definitions/rubygems_version"
else
	echo skipping rubygems…
fi
if [ "${RESTRICT:-git}" = "git" ]; then
	echo starting git…
	getLatestTag git/git > "$ROOTDIR/shared/definitions/git_version"
else
	echo skipping git…
fi
if [ "${RESTRICT:-zlib}" = "zlib" ]; then
	echo starting zlib…
	getLatestTag madler/zlib > "$ROOTDIR/shared/definitions/zlib_version"
else
	echo skipping zlib…
fi
if [ "${RESTRICT:-openssl}" = "openssl" ]; then
	echo starting openssl…
	getLatestTag openssl/openssl > "$ROOTDIR/shared/definitions/openssl_version"
else
	echo skipping openssl…
fi
if [ "${RESTRICT:-pkg-config}" = "pkg-config" ]; then
	echo starting pkg-config…
	curl --silent "https://gitlab.freedesktop.org/api/v4/projects/953/repository/tags" | ruby -rjson -e 'puts JSON.parse(STDIN.read).first["name"].split("-").last' > "$ROOTDIR/shared/definitions/pkg_config_version"
else
	echo skipping pkg-config…
fi
if [ "${RESTRICT:-gnupg}" = "gnupg" ]; then
	echo 'starting gnupg & associated…'
	curl --silent "https://www.gnupg.org/download/index.html" | \
		ruby -rnokogiri -e 'puts Nokogiri::HTML(STDIN.read).css("#text-1-1 > table > tbody > tr > td:nth-child(-n+2)").map{|e|e.text}.each_slice(2).reject{|elts| elts.first.include?(" ") && elts.first != "GnuPG (LTS)" }.map{|elts|elts.join(" ").gsub(" (LTS)","")}' | \
		tee \
			>(grep -F GnuPG | awk '{print "gnupg_version",$2}' | write_version) \
			>(grep -F Libassuan | awk '{print "libassuan_version",$2}' | write_version) \
			>(grep -F Libgcrypt | awk '{print "libgcrypt_version",$2}' | write_version) \
			>(grep -F Libgpg-error | awk '{print "libgpg_error_version",$2}' | write_version) \
			>(grep -F Libksba | awk '{print "libksba_version",$2}' | write_version) \
			>(grep -F nPth | awk '{print "npth_version",$2}' | write_version) \
			>(grep -F Pinentry | awk '{print "pinentry_version",$2}' | write_version) \
			>(grep -F ntbTLS | awk '{print "ntbtls_version",$2}' | write_version) \
			>/dev/null
else
	echo skipping gnupg…
fi
if [ "${RESTRICT:-ruby}" = "ruby" ]; then
	echo starting ruby versions…
	export OLDEST_RUBY=3.1
	curl --silent "https://www.ruby-lang.org/en/downloads/releases/" | ruby -rnokogiri -e 'puts Nokogiri::HTML(STDIN.read).css("table.release-list > tr > td:first-child").map{|e|e.text}.reject{|e|e.include?("-")}.sort.map{|e|e.split[1]}.chunk{|e|e.split(".")[0..1].join(".").to_f}.select{|major,minors|major >= ENV["OLDEST_RUBY"].to_f}.map{|major,minors|major.to_s + "." + minors.map{|e|e.split(".").last.to_i}.sort.last.to_s}' > "$ROOTDIR/shared/definitions/ruby_versions"
else
	echo skipping ruby…
fi
if [ "${RESTRICT:-libiconv}" = "libiconv" ]; then
	echo starting libiconv…
	curl --silent "https://www.gnu.org/software/libiconv/" | ruby -rnokogiri -e 'puts Nokogiri::HTML(STDIN.read).at_css("a[href^=\"https://ftp.gnu.org/pub/gnu/libiconv/libiconv-\"]").text.split("/").last.split("-").last.delete_suffix(".tar.gz")' > "$ROOTDIR/shared/definitions/libiconv_version"
else
	echo skipping libiconv…
fi
if [ "${RESTRICT:-pcre2}" = "pcre2" ]; then
	echo starting pcre2…
	getLatestTag PCRE2Project/pcre2  > "$ROOTDIR/shared/definitions/pcre2_version"
else
	echo skipping pcre2…
fi
if [ "${RESTRICT:-libreadline}" = "libreadline" ]; then
	echo starting libreadline…
	curl --silent "https://tiswww.cwru.edu/php/chet/readline/rltop.html" | ruby -rnokogiri -e 'puts Nokogiri::HTML(STDIN.read).at_css("a[href^=\"ftp://ftp.cwru.edu/pub/bash/readline-\"]").text.split("/").last.split("-").last.delete_suffix(".tar.gz")' > "$ROOTDIR/shared/definitions/libreadline_version"
else
	echo skipping libreadline…
fi
if [ "${RESTRICT:-libffi}" = "libffi" ]; then
	echo starting libffi…
	getLatestTag libffi/libffi  > "$ROOTDIR/shared/definitions/libffi_version"
else
	echo skipping libffi…
fi
if [ "${RESTRICT:-libyaml}" = "libyaml" ]; then
	echo starting libyaml…
	getLatestTag yaml/libyaml  > "$ROOTDIR/shared/definitions/libyaml_version"
else
	echo skipping libyaml…
fi

if [ "$(uname)" = "Darwin" ]; then
	echo starting macOS…
	declare -a macOS_versions
	current_macOS="$(sw_vers -ProductVersion | cut -d. -f1)"
	tr ' ' "\n" < "$ROOTDIR/shared/definitions/macosx_compatible_deployment_targets" | sort -V | mapfile -t macOS_versions
	if ! printf '%s\0' "${macOS_versions[@]}" | grep -Fxzqe "$current_macOS" && sort --check=silent <<< "${macOS_versions[-1]}\n${current_macOS}"; then
		printf '%s\n' "${macOS_versions[@]}" | tail -2 | cat - <(echo "$current_macOS") > "$ROOTDIR/shared/definitions/macosx_compatible_deployment_targets"
	fi
fi

if ! git diff --quiet --exit-code; then
	echo bumping runtime versions
	old_docker="$(cat "$ROOTDIR/shared/definitions/docker_image_version")"
	echo $((old_docker + 1)) > "$ROOTDIR/shared/definitions/docker_image_version"
	old_macOS="$(cat "$ROOTDIR/shared/definitions/macos_runtime_version")"
	echo $((old_macOS + 1)) > "$ROOTDIR/shared/definitions/macos_runtime_version"
fi
