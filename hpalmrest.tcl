
#//#
# ################################################################################
# These namespace procedure are to fetech user required information form HP ALM
# 
# @author Mallikarjunarao Kosuri
# @version 1.0
# ################################################################################

package provide hpalmrest 1.0

package require http 2.7.10
package require base64

namespace eval ::hpalm {
    namespace export {[a-z]*}
	variable headers [list]
	variable url ""
	variable status ""
	variable domain ""
	variable project ""
}

# ################################################################################
# ::hpalm::addHeaders
# Add given Headers by user
# 
# @return - void
# ################################################################################
proc ::hpalm::addHeaders {key value} {
	variable headers
	lappend headers $key $value
}

proc ::hpalm::setDomain {domain} {
	set ::hpalm::domain $domain
}

proc ::hpalm::getDomain {} {
	variable domain
	return $domain
}
proc ::hpalm::setProject {project} {
	set ::hpalm::project $project
}

proc ::hpalm::getProject {} {
	variable project
	return $project
}
# ################################################################################
# ::hpalm::getHeaders
# To get User specified headers
# 
# @return - Header List
# ################################################################################
proc ::hpalm::getHeaders {} {
	variable headers
	return $headers
}

# ################################################################################
# ::hpalm::setUrl
# To set hp alm server url to process other requrests
# 
# @return - void
# ################################################################################
proc ::hpalm::setUrl {serverUrl} {
	variable url
	set url $serverUrl
}

# ################################################################################
# ::hpalm::getUrl
# To get hp alm server url to process other requrests
# 
# @return - Hp Alm server Url
# ################################################################################
proc ::hpalm::getUrl {} {
	variable url
	return $url
}
# ################################################################################
# ::hpalm::login
# login into given hp alm
# 
# @param url - hp alm url
# @param username - corp username
# @param password - corp password
# @param domain - HP ALM domain
# @param project - HP ALM project
# @return - xml format
# ################################################################################
proc ::hpalm::login {url username password domain project} {
	variable headers
    ::hpalm::setDomain $domain
    ::hpalm::setProject $project
	::hpalm::setUrl $url
	::hpalm:::addHeaders "Content-Type" "application/xml"
	set HeadersInfo [::hpalm::getHeaders]
	array set Headers $HeadersInfo
	#parray Headers
	set authurl [concat $url/qcbin/rest/is-authenticated]
	set token [::http::geturl "$authurl" -headers [array get Headers]]
	set tokens [::http::meta $token]
	array set responseHeaders $tokens
	set lwssoCookie $responseHeaders(WWW-Authenticate)
	array unset Headers
	#set headers [list "Cookie" $lwssoCookie]
	::hpalm::addHeaders "Cookie" $lwssoCookie
	::hpalm::addHeaders "Accept" "application/xml"
	set headers [list "Authorization" "[concat Basic [base64::encode $username:$password]]"]
	::hpalm::addHeaders "Authorization" "[concat Basic [base64::encode $username:$password]]"
	set headersInfo [::hpalm::getHeaders]
	array set Headers $headersInfo
	set loginurl [concat $url/qcbin/authentication-point/authenticate]
	set token [::http::geturl "$loginurl" -headers [array get Headers]]
	set tokens [::http::meta $token]
	array set responseHeaders $tokens
	set lwssoCookie $responseHeaders(Set-Cookie)
	array unset Headers
	set headers [list "Cookie" [join $lwssoCookie ;]]
	array set Headers $headers
	set domainurl [concat $url/qcbin/rest/domains]
	set token [::http::geturl "$domainurl" -headers [array get Headers]]
	set tokens [::http::meta $token]
	array set responseHeaders $tokens
	set qcSession $responseHeaders(Set-Cookie)

	set cookie [join [list $lwssoCookie $qcSession] ";"]
	set statusCode [::http::ncode $token]
	::hpalm::clearHeaders
	
	# Construct Header which could usefule entire session.
	::hpalm:::addHeaders "Content-Type" "application/xml"
	::hpalm::addHeaders "Accept" "application/xml"
	::hpalm::addHeaders "Cookie" $cookie
	set retunXML [concat <login>\n<cookie>$cookie</cookie>\n<status>$statusCode</status>\n</login>]
	return $retunXML
}

# ################################################################################
# ::hpalm::formatQuery
# Some time ::http::formatQuery is not working  as expected,
# so better our own formatQery procedure
# Format given query inot ASCII
# ################################################################################
proc ::hpalm::formatQuery {queryString} {
	set returnVal [string map {! %21 # %23 $ %24 & %26 ' %27 ( %28 ) %29 * %29 + %2A , %2B / %2C : %3A ; %3B = %3D ? %3F @ %40 [ %5B ] %5D \{ %7B | %7C \} %7D ~ %7E < %3C > %3E ^ %5E _ %5F . %2E % %25 \" %22 " " %20 - %2D} $queryString]
	return $returnVal
}

# ################################################################################
# ::hpalm::formatQueryString
# format given query
# @param formatURL list of qureyble params
# e.g. set formatURL [list "query" "\{cycle-id\[19355\]\}" fields "user-34,test-instance"]
# @return xml content
# ################################################################################
proc ::hpalm::formatQueryString {formatURL} {
	set count 1
    set queryString ""
    array set arrayURL $formatURL
    foreach key [array names arrayURL] {
		if {$count > 1} {
			set queryString [concat "$queryString&$key=[::hpalm::formatQuery $arrayURL($key)]"]
		} else {
			set queryString [concat "$key=[::hpalm::formatQuery $arrayURL($key)]"]
		}
		incr count
    }
    return $queryString
}

# ################################################################################
# ::hpalm::GET
# Process http get method
# @param url - hp alm url
# @param formatURL list of qureyble params
# e.g. set formatURL [list "query" "\{cycle-id\[19355\]\}" fields "user-34,test-instance"]
# @return - xml format
# ################################################################################
proc ::hpalm::GET {url {formatURL ""}} {
	set headers [::hpalm::getHeaders]
	set url [concat [::hpalm::getUrl]$url]
	if {$formatURL == ""} {
		set token [::http::geturl "$url" -headers [::hpalm::getHeaders] -method GET]
	} else {
		set queryString [::hpalm::formatQueryString $formatURL]
		set token [::http::geturl "$url?$queryString" -headers [::hpalm::getHeaders] -method GET]
	}
	::hpalm::setStatus "GET" "[::http::ncode $token]"
	return [::http::data $token]
}

# ################################################################################
# ::hpalm::PUT	
# Process http put method
# 
# @param url - hp alm url
# @param queryString - query to PUT operation
# @return - xml format
# ################################################################################
proc ::hpalm::PUT {url queryString} {
	set headers [::hpalm::getHeaders]
	set url [concat [::hpalm::getUrl]$url]
    set url [::hpalm::formatQueryString $url]
	set token [::http::geturl "$url" -query "$queryString" -headers [::hpalm::getHeaders] -method PUT]
	::hpalm::setStatus "PUT" "[::http::ncode $token]"
	return [::http::data $token]
}
# ################################################################################
# ::hpalm::POST	
# Process ::http::post method
# 
# @param url - hp alm url
# @param queryString - query to PUT operation
# @return - xml format
# ################################################################################
proc ::hpalm::POST {url queryString} {
	set headers [::hpalm::getHeaders]
	set url [concat [::hpalm::getUrl]$url]
	set token [::http::geturl "$url" -query "$queryString" -headers [::hpalm::getHeaders] -method POST]
	::hpalm::setStatus "POST" "[::http::ncode $token]"
	return [::http::data $token]
}

# ################################################################################
# ::hpalm::unsetHeaders
# Clear all headers data
# ################################################################################
proc ::hpalm::clearHeaders {} {
	variable headers
	set headers ""
}

# ################################################################################
# ::hpalm::getStatus
# Returns ::http::ncode status in xml format
# @return xml format
# ################################################################################
proc ::hpalm::getStatus {} {
	variable status
	return $status
}

# ################################################################################
# ::hpalm::setStatus
# SStore current ::http::nocd status into status variable
# @return void
# ################################################################################
proc ::hpalm::setStatus {procName ncode} {
	variable status
	# Clear previous status code if stored.
	set status ""
	set status [concat <$procName><status>$ncode</status></$procName>]
}

# ################################################################################
# ::hpalm::AddReportAttachment
# Add Report to given test instance
# @param reportId report identifier to attach
# @param fileName file name to upload into hp alm
# @return xml content
# ################################################################################
proc ::hpalm::AddReportAttachment {url reportId fileName} {
	set fd ""
	set fileText ""
	if {[file exists "$fileName"]} {
		set fd [open "$fileName" r]
		set fileText [read $fd]
	}
	set slugFileName [file tail $fileName]
	set headers [::hpalm::getHeaders]
	array set Headers $headers
	set Headers(Content-Type) "application/octet-stream"
	set Headers(Slug) "$slugFileName"
	set url [concat [::hpalm::getUrl]$url]
	set token [::http::geturl "$url" -query [concat $fileText] -headers [array get Headers] -method POST]
	return [concat <AddReportAttachment><status>[::http::ncode $token]</status></AddReportAttachment>]
}

# ################################################################################
# ::hpalm::GetReportAttachment
# Add Report to given test instance
# @param reportId report identifier to attach
# @return xml content
# ################################################################################
proc ::hpalm::GetReportAttachment {url} {
	set headers [::hpalm::getHeaders]
	array set Headers $headers
	set Headers(Accept) "application/octet-stream"
	set url [concat [::hpalm::getUrl]$url]
    # set url [::hpalm::formatQueryString $url]
	set token [::http::geturl "$url" -headers [array get Headers] -method GET]
	return [::http::data $token]
}

# ################################################################################
# ::hpalm::UpdateRunStatus
# Modify existing report status i.e either Passed|Failed
# @param url URL hp alm
# @param Status needs to change report status
# @return xml content
# ################################################################################
proc ::hpalm::UpdateRunStatus {url status} {
	for {set i 0} {$i < 2} {incr i} {
		if {$status == "Passed"} {
			set status "Failed"
			set xml [concat <Entity Type="run"><Fields><Field Name="status"><Value>$status</Value></Field></Fields></Entity>]
			::hpalm::PUT $url [concat $xml]
		} else {
			set status "Passed"
			set xml [concat <Entity Type="run"><Fields><Field Name="status"><Value>$status</Value></Field></Fields></Entity>]
			::hpalm::PUT $url [concat $xml]
		}
	}
	set status [::hpalm::getStatus]
	return [concat <UpdateRunStatus><status>$status</status></UpdateRunStatus>]
}

# ################################################################################
# ::hpalm::Logout
# Logout from HP ALM
# 
# @return xml content
# ################################################################################
proc ::hpalm::Logout {} {
	set url [concat [::hpalm::getUrl]/qcbin/authentication-point/logout]
	set token [::http::geturl $url -headers [::hpalm::getHeaders] -method GET]
	return [concat <Logout><status>[::http::ncode $token]</status></Logout>]
}
