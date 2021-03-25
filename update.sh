#/usr/bin/env bash

ROOTDIR=$(dirname "$0")
read -p "Enter Your GitHub Token: " TOKEN
echo

write_version() {
	read file version
	echo $version > $ROOTDIR/shared/definitions/$file
}

getLatest() {
	curl -H "Authorization: token $TOKEN" --silent "https://api.github.com/repos/$1/releases/latest" | ruby -rjson -e 'puts JSON.parse(STDIN.read)["tag_name"].delete_prefix("v").gsub("_",".").delete_prefix("curl-")'
}

getLatestTag() {
	PAGES=$(curl -H "Authorization: token $TOKEN" -I --silent "https://api.github.com/repos/$1/tags" | fgrep 'Link:' | awk -F, '{print $2}' | sed -Ee 's/.*<(.*)>.*/\1/g' | awk -F= '{print $2}')
	for PAGE in $(seq 1 ${PAGES:-1}); do curl -H "Authorization: token $TOKEN" --silent "https://api.github.com/repos/$1/tags?page=$PAGE"; done | ruby -rjson -e 'puts JSON.parse(STDIN.read.gsub(/\][\n]*\[/,",")).map{|e|e["name"]}.reject{|e|["rc","gitgui","fips","levitte","-engine-","beta","ssleay","master","before","after","pre","post","rsaref","alpha","1000"].any?{|s|e.downcase.include?(s)}}.map{|s|s.delete_prefix("v").delete_prefix("OpenSSL_").gsub("_",".")}' | sort -V | tail -1
}
if [ ${RESTRICT:-cmake} = "cmake" ]; then
	echo starting cmake…
	getLatestTag Kitware/CMake > $ROOTDIR/shared/definitions/cmake_version
else
	echo skipping cmake…
fi
if [ ${RESTRICT:-ccache} = "ccache" ]; then
	echo starting ccache…
	getLatest ccache/ccache > $ROOTDIR/shared/definitions/ccache_version
else
	echo skipping ccache…
fi
if [ ${RESTRICT:-curl} = "curl" ]; then
	echo starting curl…
	getLatest curl/curl     > $ROOTDIR/shared/definitions/curl_version
else
	echo skipping curl…
fi
if [ ${RESTRICT:-geoip} = "geoip" ]; then
	echo starting geoip…
	getLatest maxmind/geoip-api-c > $ROOTDIR/shared/definitions/geoip_version
else
	echo skipping geoip…
fi
if [ ${RESTRICT:-s3cmd} = "s3cmd" ]; then
	echo starting s3cmd…
	getLatest s3tools/s3cmd > $ROOTDIR/shared/definitions/s3cmd_version
else
	echo skipping s3cmd…
fi
if [ ${RESTRICT:-zstd} = "zstd" ]; then
	echo starting zstd…
	getLatest facebook/zstd > $ROOTDIR/shared/definitions/zstd_version
else
	echo skipping zstd…
fi
if [ ${RESTRICT:-rubygems} = "rubygems" ]; then
	echo starting rubygems…
	getLatestTag rubygems/rubygems > $ROOTDIR/shared/definitions/rubygems_version
else
	echo skipping rubygems…
fi
if [ ${RESTRICT:-git} = "git" ]; then
	echo starting git…
	getLatestTag git/git > $ROOTDIR/shared/definitions/git_version
else
	echo skipping git…
fi
if [ ${RESTRICT:-zlib} = "zlib" ]; then
	echo starting zlib…
	getLatestTag madler/zlib > $ROOTDIR/shared/definitions/zlib_version
else
	echo skipping zlib…
fi
if [ ${RESTRICT:-openssl} = "openssl" ]; then
	echo starting openssl…
	getLatestTag openssl/openssl > $ROOTDIR/shared/definitions/openssl_version
else
	echo skipping openssl…
fi
if [ ${RESTRICT:-pkg-config} = "pkg-config" ]; then
	echo starting pkg-config…
	curl --silent "https://gitlab.freedesktop.org/api/v4/projects/953/repository/tags" | ruby -rjson -e 'puts JSON.parse(STDIN.read).first["name"].split("-").last' > $ROOTDIR/shared/definitions/pkg_config_version
else
	echo skipping pkg-config…
fi
if [ ${RESTRICT:-gnupg} = "gnupg" ]; then
	echo 'starting gnupg & associated…'
	curl --silent "https://www.gnupg.org/download/index.html" | ruby -rnokogiri -e 'puts Nokogiri::HTML(STDIN.read).css("#text-1-1 > table > tbody > tr > td:nth-child(-n+2)").map{|e|e.text}.each_slice(2).reject{|elts| elts.first.include?(" ") && elts.first != "GnuPG (LTS)" }.map{|elts|elts.join(" ").gsub(" (LTS)","")}' | tee >(fgrep GnuPG | awk '{print "gnupg_version",$2}' | write_version) >(fgrep Libassuan | awk '{print "libassuan_version",$2}' | write_version) >(fgrep Libgcrypt | awk '{print "libgcrypt_version",$2}' | write_version) >(fgrep Libgpg-error | awk '{print "libgpg_error_version",$2}' | write_version) >(fgrep Libksba | awk '{print "libksba_version",$2}' | write_version) >(fgrep nPth | awk '{print "npth_version",$2}' | write_version) >(fgrep Pinentry | awk '{print "pinentry_version",$2}' | write_version) >/dev/null
else
	echo skipping gnupg…
fi
if [ ${RESTRICT:-ruby} = "ruby" ]; then
	echo starting ruby versions…
	curl --silent "https://www.ruby-lang.org/en/downloads/releases/" | ruby -rnokogiri -e 'puts Nokogiri::HTML(STDIN.read).css("table.release-list > tr > td:first-child").map{|e|e.text}.reject{|e|e.include?("-")}.sort.map{|e|e.split[1]}.chunk{|e|e.split(".")[0..1].join(".").to_f}.select{|major,minors|major > 2.2}.map{|major,minors|major.to_s + "." + minors.map{|e|e.split(".").last.to_i}.sort.last.to_s}' > $ROOTDIR/shared/definitions/ruby_versions
else
	echo skipping ruby…
fi
if [ ${RESTRICT:-libiconv} = "libiconv" ]; then
	echo starting libiconv…
	curl --silent "https://www.gnu.org/software/libiconv/" | ruby -rnokogiri -e 'puts Nokogiri::HTML(STDIN.read).at_css("a[href^=\"https://ftp.gnu.org/pub/gnu/libiconv/libiconv-\"]").text.split("/").last.split("-").last.delete_suffix(".tar.gz")' > $ROOTDIR/shared/definitions/libiconv_version
else
	echo skipping libiconv…
fi
if [ ${RESTRICT:-pcre} = "pcre" ]; then
	echo starting pcre…
	curl --silent "https://www.pcre.org/" | ruby -rnokogiri -e 'puts Nokogiri::HTML(STDIN.read).at_css("h2 + p + p > b").text' > $ROOTDIR/shared/definitions/pcre_version
else
	echo skipping pcre…
fi
