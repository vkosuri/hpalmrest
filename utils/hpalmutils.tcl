
#//#
# ################################################################################
# These namespace procedure are to fetch user required information form HP ALM <br />
# 
# @author Mallikarjunarao Kosuri <br />
# @version 1.0 <br />
# ################################################################################

package provide hpalmutils 1.0

package require hpalmrest
package require tdom


namespace eval ::hpalm::util {
    namespace export {[a-z]*}
}

# ################################################################################
# ::hpalm::util::::hpalm::util::GetNodeValue <br />
# Return tdom node value <br />
# @param response: HP ALM xml response <br />
# @param xpath: xpath url for get resource <br />
# @return - tdom nodeValue <br />
# ################################################################################
proc ::hpalm::util::GetNodeValue {response xpath} {
    set doc ""
    set root ""
    set node ""
    set doc [dom parse $response]
    set root [$doc documentElement]
    set node [$root selectNodes $xpath]
    # $root delete
    return [$node nodeValue]
}
# ################################################################################
# ::hpalm::util::::hpalm::util::::hpalm::util::GetNodeValueList <br />
# Return tdom node value list <br />
# @param response: HP ALM xml response <br />
# @param xpath: xpath url for get resource <br />
# @return - tdom nodeValue <br />
# ################################################################################
proc ::hpalm::util::GetNodeValueList {response xpath} {
    set doc ""
    set root ""
    set node ""
    set listOfItems ""
    set doc [dom parse $response]
    set root [$doc documentElement]
    set nodeList [$root selectNodes $xpath]
    foreach node $nodeList {
        lappend listOfItems [$node nodeValue]
    }
    # $root delete
    return $listOfItems
}

# ################################################################################
# ::hpalm::util::GetTestsetId <br />
# This procedure will return testset id in hpalm through rest procedure calls <br />
# @param testsetPath report identifier to attach <br />
# @return testsetId <br />
# ################################################################################
proc ::hpalm::util::GetTestsetId {testsetPath} {
    set domain [::hpalm::getDomain]
    set project [::hpalm::getProject]
    # puts $domain
    # puts $project
    set testsetPath [split $testsetPath "/"]
    # puts $testsetPath
    set parentId -1
    for {set i 0} {$i < [llength $testsetPath]} {incr i} {
        if {[lindex $testsetPath $i] == "Root"} {
            set parentId 0
        } elseif {$i < [expr [llength $testsetPath] - 1]} {
            set url [concat /qcbin/rest/domains/$domain/projects/$project/test-set-folders]
            set queryCaluse [concat \{name\[\'[lindex $testsetPath $i]\'\]\; parent-id\[$parentId\]\}]
            set response [::hpalm::GET $url [list "query" "[concat $queryCaluse]"]]
            set doc [dom parse $response]
            set root [$doc documentElement]
            set totalResults [$root getAttribute TotalResults]
            $root delete
            # puts "Results: $totalResults"
            if {$totalResults == 0} {
                puts "Enter valid Testset path"
                return 0;
             }
            # puts "Response: $response"
            set parentId [::hpalm::util::GetNodeValue $response "Entity/Fields/Field\[@Name='id'\]/Value/text()"]
        } else {
            set url [concat /qcbin/rest/domains/$domain/projects/$project/test-sets]
            set queryCaluse [concat \{parent-id\[$parentId\]\; name\[\'[lindex $testsetPath $i]\'\]\}]
            set response [::hpalm::GET $url [list "query" "[concat $queryCaluse]"]]
            # puts "REs: $response"
            set testsetId [::hpalm::util::GetNodeValue $response "Entity/Fields/Field\[@Name='id'\]/Value/text()"]            
        }
    }
    return $testsetId
}

# ################################################################################
# ::hpalm::util:GetTestsetIdList <br />
# This procedure will return list of testset ids in a given test set <br />
# @param testsetId HP ALM test set identifier <br />
# @return list of test set identifier <br />
# ################################################################################
proc ::hpalm::util::GetTestIdList {testsetId} {
    set domain [::hpalm::getDomain]
    set project [::hpalm::getProject]
    set queryCaluse [concat \{cycle-id\[$testsetId\]\}]
    set url [concat /qcbin/rest/domains/$domain/projects/$project/test-instances]
    set response [::hpalm::GET "$url" [list "query" $queryCaluse]]
    set testIdList [::hpalm::util::GetNodeValueList $response "Entity/Fields/Field\[@Name='test-id'\]/Value/text()"]
    return $testIdList
}

# ################################################################################
# :::hpalm::util:GetTestsetInstancesList <br />
# This procedure will return list of test-instances in a given test set <br />
# @param testsetId HP ALM test-instances <br />
# @return list of test-instances <br />
# ################################################################################
proc ::hpalm::util::GetTestsetInstancesList {testsetId} {
    set domain [::hpalm::getDomain]
    set project [::hpalm::getProject]
    set queryCaluse [concat \{cycle-id\[$testsetId\]\}]
    set url [concat /qcbin/rest/domains/$domain/projects/$project/test-instances]
    set response [::hpalm::GET "$url" [list "query" $queryCaluse]]
    set testInstancesList [::hpalm::util::GetNodeValueList $response "Entity/Fields/Field\[@Name='test-instance'\]/Value/text()"]
    return $testInstancesList
}

# ################################################################################
# ::hpalm::util:GetTestInstanceRunId <br />
# ################################################################################
proc ::hpalm::util::GetTestInstanceRunId {testsetId testid testIns} {
    set domain [::hpalm::getDomain]
    set project [::hpalm::getProject]
    set queryCaluse [concat \{cycle-id\[$testsetId\]\; test-id\[$testid\]\; test-instance\[$testIns\]\; status\[Passed or Failed\]\}]
    set orderByCaluse [concat \{execution-date\; id\[ASC\]\}]
    set url [concat /qcbin/rest/domains/$domain/projects/$project/runs]
    set response [::hpalm::GET $url [list "query" "[concat $queryCaluse]" "order-by" "[concat $orderByCaluse]"]]
    set doc [dom parse $response]
    set root [$doc documentElement]
    set totalResults [$root getAttribute TotalResults]
    $root delete
    if {$totalResults == 0} {
        # puts "Enter valid Testset path"
        return 0;
    }
    set runId [::hpalm::util::GetNodeValue $response "(Entity/Fields/Field\[@Name='id'\]/Value/text()) \[last()\]"]
    return $runId
}

# ################################################################################
# ::hpalm::util:PlaceRunIdAttachments <br />
# ################################################################################
proc ::hpalm::util::PlaceRunIdAttachments {runId logDir fileType} {
    set domain [::hpalm::getDomain]
    set project [::hpalm::getProject]
    set url [concat /qcbin/rest/domains/$domain/projects/$project/runs/$runId/attachments]
    set response [::hpalm::GET "$url"]
    set doc [dom parse $response]
    set root [$doc documentElement]
    set totalResults [$root getAttribute TotalResults]
    # puts "Results: $totalResults"
    if {$totalResults == 0} {
        return 0;
    } elseif {$totalResults > 1} {
        set fileSize [::hpalm::util::GetNodeValueList $response "Entity/Fields/Field\[@Name='file-size'\]/Value/text()"]
        set fileName [::hpalm::util::GetNodeValueList $response "Entity/Fields/Field\[@Name='name'\]/Value/text()"]
        set logExtension [concat *$fileType]
        set logFile [lsearch -all -inline  $fileName $logExtension]
        set logFile [lindex $logFile 0]
    } else {
        set fileSize [::hpalm::util::GetNodeValue $response "Entity/Fields/Field\[@Name='file-size'\]/Value/text()"]
        set fileName [::hpalm::util::GetNodeValue $response "Entity/Fields/Field\[@Name='name'\]/Value/text()"]
        set logFile $fileName      
    }
    if {$logFile == ""} {
        return 0;
    }
    set formatLogFile [::hpalm::formatQuery $logFile]
    # puts $formatLogFile
    # puts "logFileList: $logFileList" 
    set url [concat /qcbin/rest/domains/$domain/projects/$project/runs/$runId/attachments/$formatLogFile]
    # puts $url
    set logResponse [::hpalm::GetReportAttachment "$url"]
    set writeFile [concat $logDir/$logFile]
    # puts "writeFileName: $writeFile"
    set fileId [open $writeFile {WRONLY CREAT}]
    puts $fileId $logResponse
    close $fileId        
}


# ################################################################################
# ::hpalm::util::AddReportEntity <br />
# ################################################################################
proc ::hpalm::util::AddReportEntity {testName status duration tester} {
    set domain [::hpalm::getDomain]
    set project [::hpalm::getProject]
    set queryCaluse [concat \\\{name\\\[\\\"$testName\\\"\\\]\\\}]
    set url [concat /qcbin/rest/domains/$domain/projects/$project/tests]
    ::HpAlmRest::GET "$url" \[list "query" "$queryCaluse"\]
    --need query
    set testId [mapped/Xml/Entities/Entity/Fields/Field[@Name='id']/Value]
    set testType [mapped/Xml/Entities/Entity/Fields/Field[@Name='subtype-id']/Value]
    
    set url [concat /qcbin/rest/domains/$domain/projects/$project/test-configs]
    ::HpAlmRest::GET "$url" \[list "query" "$queryCaluse"\]
    set testConfigId [mapped/Xml/Entities/Entity/Fields/Field[@Name='id']/Value]
    
    set url [concat /qcbin/rest/domains/$domain/projects/$project/test-instances]
    set testType [string map {VAPI-XP-TEST hp.qc.run.VAPI-XP-TEST ITEST custom.run.ITEST} $testType]
    set queryCaluse [concat \\\{cycle-id\\\[$testSetId\\\]\\\; test\-instance\\\[$testInstanceNumber\\\]\\\}]
    ::HpAlmRest::GET "$url" \[list "query" "$queryCaluse"\]
    set testInstanceId [mapped/Xml/Entities/Entity/Fields/Field[@Name='id']/Value]
    
    set xml [concat <Entity Type="run"><Fields><Field Name="cycle-id"><Value>$testSetId</Value></Field><Field Name="name"><Value>$testRunName</Value></Field><Field Name="test-id"><Value>$testId</Value></Field><Field Name="testcycl-id"><Value>$testInstanceId</Value></Field><Field Name="subtype-id"><Value>$testType</Value></Field><Field Name="test-config-id"><Value>$testConfigId</Value></Field><Field Name="status"><Value>$status</Value></Field><Field Name="duration"><Value>$duration</Value></Field><Field Name="test-instance"><Value>$testInstanceNumber</Value></Field><Field Name="owner"><Value>$tester</Value></Field></Fields></Entity>]
    
    set url [concat /qcbin/rest/domains/$domain/projects/$project/runs]
    ::HpAlmRest::POST "$url" "\[concat $xml\]"
    set runId [mapped/Xml/Entities/Entity/Fields/Field[@Name='id']/Value]
    ::HpAlmRest::getStatus
}

# ################################################################################
# ::hpalm::util::UpdateRunStatus <br />
# ################################################################################
proc ::hpalm::util::UpdateRunStatus {runId} {
    set url [concat /qcbin/rest/domains/$domain/projects/$project/runs/$runId]
    ::HpAlmRest::UpdateRunStatus $url $status
}

# ################################################################################
# ::hpalm::util:AddReportAttachment <br />
# ################################################################################
proc ::hpalm::util:AddReportAttachment {runId fileName} {
    set url [concat /qcbin/rest/domains/$domain/projects/$project/runs/$runId/attachments]
    ::HpAlmRest::AddReportAttachment $url $runId [concat $fileName]
}

# ################################################################################
# ::hpalm::util:AddRunstep <br />
# This procedure will return response of given test set instance <br />
# which is in passed or failed state in a test set id <br />
# @param testsetId HP ALM test set identifier <br />
# @param testid test identifier <br />
# @param testIns test instance id <br />
# @return response/ouput of a given file else return 0 <br />
# ################################################################################
proc ::hpalm::util::AddRunstep {stepName stepStatus reportId} {
    set xml [concat <Entity><Fields><Field Name="name"><Value>$stepName</Value></Field><Field Name="Status"><Value>$stepStatus</Value></Field><Field Name="parent-id"><Value>$reportId</Value></Field></Fields></Entity>]
    set url [concat /qcbin/rest/domains/$domain/projects/$project/runs/$reportId/run-steps]
    ::HpAlmRest::POST "$url" "\[concat $xml\]"
    ::HpAlmRest::getStatus
}

# ################################################################################
# ::hpalm::util:UpdateTestInstanceExecutionDate <br />
# ###############################################################################
proc ::hpalm::util::UpdateTestInstanceExecutionDate {testSetId testInstanceId executionDate} {
    set queryCaluse [concat \\\{cycle-id\\\[$testSetId\\\]\\\;test-instance\\\[$testInstanceId\\\]\\\}]
    set url [concat /qcbin/rest/domains/$domain/projects/$project/test-instances]
    set xml [concat <Entity Type="test-instance"><Fields><Field Name="exec-date"><Value>$executionDate</Value></Field></Fields></Entity>]
    ::HpAlmRest::GET $url \[list "query" "$queryCaluse"\]
    mapped/Xml/Entities/Entity/Fields/Field[@Name='id']/Value
    set url [concat /qcbin/rest/domains/$domain/projects/$project/test-instances/$testInstanceId]
    set status [::HpAlmRest::PUT "$url" \[concat $xml\]]
    ::HpAlmRest::getStatus
}
