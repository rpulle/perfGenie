<script>
    /*
* Copyright (c) 2022, Salesforce.com, Inc.
* All rights reserved.
* SPDX-License-Identifier: BSD-3-Clause
* For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
*/
</script>
<div tabindex="-1" id="SampleprofileID" class='ui-widget' style="padding-left: 0px;">
    <label>Profile: </label>
    <select  style="height:30px;text-align: center;" class="filterinput" name="event-type-sample" id="event-type-sample">

    </select>
    <label style='display:none'>Event: </label>
    <select  style="height:30px;text-align: center;display:none" class="filterinput"  name="event-input-smpl" id="event-input-smpl">

    </select>

    <label >Format: </label>
    <select  style="height:30px;text-align: center;" class="filterinput"  name="sample-format-input" id="sample-format-input">
        <option selected value=0>table</option>
        <option value=1>thread sample view</option>
    </select>


        <label  title="group by tid will show all samples in a thread, others need a matching context">Group by: </label>
        <select  style="height:30px;text-align: center;" class="filterinput"  name="smpl-grp-by" id="smpl-grp-by">
        </select>
    <span id="extraoptions">
        <span title="Consider first N characters of group by option values">Len:</span><input  style="height:30px;width:35px;text-align: left;" class="filterinput" id="samples-groupby-length" type="text" value="">
        <span title="Sub string match with group by option values">Match:</span><input  style="height:30px;width:120px;text-align: left;" class="filterinput" id="samples-groupby-match" type="text" value="">
    </span>
</div>

<div class="row">
<div style="padding: 0px !important;overflow: scroll"  id="sampletablecontext" class="ui-widget sampletable col-lg-12">
</div>
</div>

<div class="row">
    <div class="col-lg-7">
        <div style="overflow: auto; padding-left: 0px;padding-right: 2px; width: 100%;" class="cct-customized-scrollbar">
            <div style="padding: 0px !important;"  id="sampletable" class="ui-widget sampletable col-lg-12">
            </div>
        </div>
    </div>
    <div style="padding-left: 0px !important;" id="quick-stack-view" class="col-lg-5">
        <a id="detail-stack-view-link" target="_blank"></a>
        <label id="stack-view-java-label-guid">Stack Trace</label>
        <pre class="small" style="max-height: 900px; min-height: 900px; overflow-y: scroll;" id="stack-view-guid" >
            Click on a sample to see the Java stack here...
        </pre>
    </div>
</div>

<style>
    .sampletoolbar {
        padding-bottom: 2px;
    }
</style>

<script>
    let sampleTable = undefined;
    let sampleTablePage = 0;
    let stack_id = undefined;
    let smplBy = '';
    let samplesCustomEvent = '';
    let samplesgroupByLength = '';
    let samplesgroupByMatch = '';
    function updateEventInputOptions(id){
        $('#'+id).empty();

        /*
        let localContextData = getContextData(1);
        if (localContextData != undefined && localContextData.records != undefined) {
            let samplesCustomEventFound = false;
            if(!(samplesCustomEvent == '' || samplesCustomEvent == undefined)) {
                for (let value in localContextData.records) {
                    if(samplesCustomEvent == value){
                        samplesCustomEventFound = true;
                        break;
                    }
                }
            }

            for (let value in localContextData.records) {
                if(samplesCustomEvent == '' || samplesCustomEvent == undefined || !samplesCustomEventFound){
                    samplesCustomEvent = value;
                    samplesCustomEventFound=true;
                }
                $('#'+id).append($('<option>', {
                    value: value,
                    text: value,
                    selected: (samplesCustomEvent == value)
                }));
            }
        }*/

        //filters are not applied, so we should use only customEvent everywhere
        samplesCustomEvent = customEvent;
        $('#'+id).append($('<option>', {
            value: samplesCustomEvent,
            text: samplesCustomEvent,
            selected: true
        }));

        $("#samples-groupby-length").val(samplesgroupByLength);
        $("#samples-groupby-match").val(samplesgroupByMatch);
    }

    function updateSampleFormatOptions(id){
        $('#'+id).empty();
        $('#' + id).append($('<option>', {
            value: 0,
            text: "table",
            selected: (sampletableFormat == 0)
        }));
        $('#' + id).append($('<option>', {
            value: 1,
            text: "thread sample view",
            selected: (sampletableFormat == 1)
        }));
    }

    function updateGroupByOptions(id){
        $('#'+id).empty();
        let localContextData = getContextData(1);

        if (localContextData != undefined && localContextData.header != undefined) {
            let groups = [];
            for (let val in localContextData.header[samplesCustomEvent]) {
                const tokens = localContextData.header[samplesCustomEvent][val].split(":");
                if (tokens[1] == "text" || tokens[1] == "timestamp") {
                    groups.push(tokens[0]);
                }
            }
            groups.sort();

            let groupByFound = false;
            if(!(smplBy == '' || smplBy == undefined)) {
                for (let val in localContextData.header[samplesCustomEvent]) {
                    const tokens = localContextData.header[samplesCustomEvent][val].split(":");
                    if(smplBy == tokens[0]){
                        groupByFound = true;
                        break;
                    }
                }
            }

            if(fContext == 'without'){//without context supported only for tid
                $('#' + id).append($('<option>', {
                    value: 'tid',
                    text: 'tid',
                    selected: true
                }));
            }else {
                if ((smplBy == '' || smplBy == undefined || !groupByFound)) {
                    for (let i = 0; i < groups.length; i++) {
                        if (groups[i] == "uri") {//SFDC default
                            smplBy = groups[i];
                            groupByFound = true;
                            break;
                        }
                    }
                }

                for (let i = 0; i < groups.length; i++) {
                    if ((smplBy == '' || smplBy == undefined || !groupByFound)) {
                        smplBy = groups[i];
                        groupByFound = true;
                    }
                    if (smplBy == groups[i]) {
                        $('#' + id).append($('<option>', {
                            value: groups[i],
                            text: groups[i],
                            selected: true
                        }));
                    } else {
                        $('#' + id).append($('<option>', {
                            value: groups[i],
                            text: groups[i]
                        }));
                    }
                }
            }
        }
    }

    $("#smpl-grp-by").on("change", (event) => {
        updateUrl("smplBy",$("#smpl-grp-by").val(),true);
        smplBy = $("#smpl-grp-by").val();
        genSampleTable(false, undefined);
    });

    $("#event-input-smpl").on("change", (event) => {
        updateUrl("scustomevent",$("#event-input-smpl").val(),true);
        samplesCustomEvent = $("#event-input-smpl").val();
        updateProfilerViewSample(getSelectedLevel(getContextTree(1,getEventType())),true);
    });

    $("#sample-format-input").on("change", (event) => {

        updateUrl("sampletableFormat", $("#sample-format-input").val(), true);
        sampletableFormat = $("#sample-format-input").val();

        if(sampletableFormat == 1 || sampletableFormat == 0) {
            if($("#event-type-sample option[value='All']").length ==0)
            {
                $('#event-type-sample').append($('<option>', {
                    value: "All",
                    text: "All"
                }));
            }
        }

        updateProfilerViewSample(getSelectedLevel(getContextTree(1,getEventType())),true);
    });

    $("#event-type-sample").on("change", (event) => {
        if($("#event-type-sample").val() == "All"){
            updateProfilerViewSample(getSelectedLevel(getContextTree(1,getEventType())),true);
        }else {
            handleEventTypeChange($("#event-type-sample").val());
        }
    });

    $("#samples-groupby-match").on("change", (event) => {
        updateUrl("sgroupByMatch", $("#samples-groupby-match").val(), true);
        samplesgroupByMatch = $("#samples-groupby-match").val();
        updateProfilerViewSample(getSelectedLevel(getContextTree(1,getEventType())),true);
    });
    $("#samples-groupby-length").on("change", (event) => {
        updateUrl("sgroupByLength", $("#samples-groupby-length").val(), true);
        samplesgroupByLength = $("#samples-groupby-length").val();
        updateProfilerViewSample(getSelectedLevel(getContextTree(1,getEventType())),true);
    });

    $(document).ready(function () {

        smplBy=urlParams.get('smplBy');// || 'tid';
        sampleTablePage=urlParams.get('spage') || '0';
        stack_id=urlParams.get('stack_id') || '';
        samplesCustomEvent=urlParams.get('scustomevent') || '';
        samplesgroupByMatch = urlParams.get('sgroupByMatch') || '';
        samplesgroupByLength = urlParams.get('sgroupByLength') || '200';

        let filterType = smplBy;

        let str = "<table   style=\"width: 100%;\" id=\"sample-table\" class=\"table compact table-striped table-bordered  table-hover dataTable\"><thead><tr><th width=\"50%\">" + getHearderFor(filterType) + "</th><th width=\"10%\">Sample Count</th><th width=\"40%\">Samples</th></thead>";
        str = str + "</table>";
        document.getElementById("sampletable").innerHTML = str;
        $('#sample-table').DataTable({
            "order": [[1, "desc"]],
            searching: false,
            "columnDefs": [{
                "targets": 0,
                "orderable": false
            }],
            "sDom": '<"sampletoolbar">frtip'
        });

        updateEventInputOptions('event-input-smpl');

        updateGroupByOptions('smpl-grp-by');
        updateSampleFormatOptions('sample-format-input');
        //validateInputAndcreateContextTree(true);
    });


    let eventTypeMaxThreadSamples={};
    function prepSamplesData(eventType){
        let profile = getContextTree(1, eventType);
        if(profile.times != undefined){
            end = performance.now();
            console.log("prepData skip for:" + eventType);
            return;//done only once
        }
        let tmpTimestampap = {};
        let timestampArray = [];

        let start = performance.now();

        let tidMap = profile.context.tidMap;

        //generate unique timestamp array
        for (var k in tidMap) {
            for (let i = 0; i < tidMap[k].length; i++) {
                if(tmpTimestampap[tidMap[k][i].time] == undefined) {
                    tmpTimestampap[tidMap[k][i].time] = true;
                    timestampArray.push(tidMap[k][i].time);
                }
            }
        }
        timestampArray.sort(function (a, b) {
            return a - b
        });
        let prev = timestampArray[0];
        let count = 0;
        for(let i = 0; i<timestampArray.length; i++){
            if((timestampArray[i]-prev) > 60000){
                tmpTimestampap[Math.round((timestampArray[i]+prev)/2)] = -1;
                count++;
            }
            tmpTimestampap[timestampArray[i]] = i;
            prev = timestampArray[i];
            count++;
        }
        eventTypeMaxThreadSamples[eventType]=count;

        profile.times = tmpTimestampap;
        end = performance.now();
        console.log("prepSamplesData time :" + (end - start));
    }

    function getSamplesTableHeader(groupBySamples, row, event) {

        let localContextData = getContextData(1);
        /*if(event === EventType.MEMORY) {
            totalSampleCount = totalSampleCount * 1024 * 1024;
            if(groupBySamples == "tid") {
                sfContextDataTable.addContextTableHeader(row,groupBySamples,1,"class='context-menu-two'");
            }else{
                sfContextDataTable.addContextTableHeader(row,groupBySamples,-1,"class='context-menu-two'");
            }
            sfContextDataTable.addContextTableHeader(row,"Memory Mb",1);
            sfContextDataTable.addContextTableHeader(row,"Samples",1);
        }else{*/
            if(groupBySamples == "tid") {
                sfSampleTable.addContextTableHeader(row,groupBySamples,1,"class='context-menu-three'",localContextData.tooltips[groupBySamples]);
            }else{
                sfSampleTable.addContextTableHeader(row,groupBySamples,-1,"class='context-menu-two'",localContextData.tooltips[groupBySamples]);
            }
            sfSampleTable.addContextTableHeader(row,"Sample Count",1);
            sfSampleTable.addContextTableHeader(row,"Samples",1);
        //}
    }

    let sampleTableRows = [];
    let sampleTableHeader = [];
    let moreSamples = [];

    const sfSampleTable = new SFDataTable("sfSampleTable");
    Object.freeze(sfSampleTable);

    let sampleSortMap = undefined;
    function genSampleTable(addContext, level) {

        let eventType = getEventType();
        let jfrprofilestart = 0;

        let tempeventTypeArray = [];
        for (var tempeventType in jfrprofiles1) {//for all profile event types
            tempeventTypeArray.push(tempeventType);
            if (jfrprofilestart == 0 && !(tempeventType == "Jstack" || tempeventType == "json-jstack") && getContextTree(1, tempeventType) != undefined) {
                jfrprofilestart = getContextTree(1, tempeventType).context.start;
            }
        }
        tempeventTypeArray.sort();

        let jstackdiff = 0;
        let jstactprofilestart = 0;
        let jstackEvent = getContextTree(1, "json-jstack") == undefined ?  "Jstack" : "json-jstack";
        if (getContextTree(1, jstackEvent) !== undefined) {
            jstackdiff = getContextTree(1, jstackEvent).context.start - jfrprofilestart;
            jstactprofilestart = getContextTree(1, jstackEvent).context.start;
        }

        let tidSamplesTimestamps = {};
        let dimIndexMap = {};
        let metricsIndexMap = {};
        let metricsIndexArray = [];
        let spanIndex = -1;
        let timestampIndex = -1;
        let tidRowIndex = -1;

        let sampleCountMap = new Map();
        sampleSortMap = new Map();

        $('#stack-view-guid').text("");
        let start1 = performance.now();
        let groupBySamples = smplBy;
        sampleTableHeader = [];
        sampleTableRows = [];
        moreSamples = [];

        if(fContext == 'without'){//context without supported only for tid, todo support thread name for jstacks
            groupBySamples = 'tid';
        }
        getSamplesTableHeader(groupBySamples, sampleTableHeader, eventType);
        let totalSampleCount = getContextTree(1, eventType).tree.sz;
        let samplerowIndex = -1;

        if(addContext) {
            updateEventInputOptions('event-input-smpl');
            updateGroupByOptions('smpl-grp-by');
            updateSampleFormatOptions('sample-format-input');
        }

        let isAll = (fContext === 'all' || fContext === '');
        let isWith = (fContext === 'with');

        let localContextData = getContextData(1);
        //let table = "<table   style=\"width: 100%;\" id=\"sample-table\" class=\"table compact table-striped table-bordered  table-hover dataTable\"><thead><tr><th width=\"50%\">" + getHearderFor(groupBySamples) + "</th><th width=\"10%\">Sample Count</th><th width=\"40%\">Samples</th></thead>";
        for (let tempeventTypeCount = 0; tempeventTypeCount< tempeventTypeArray.length; tempeventTypeCount++){
            let eventSampleCount = 0;
            let isJstack = false;
            if($("#event-type-sample").val() == "All"){//process all events
                eventType = tempeventTypeArray[tempeventTypeCount];
                applyContextFilters(eventType,level);
                addContext=true;
            }else if(tempeventTypeArray[tempeventTypeCount] != eventType){
                continue;
            }
            if (addContext) {
                addContextData(eventType, 1);
            }


            for (let val in localContextData.header[samplesCustomEvent]) {
                const tokens = localContextData.header[samplesCustomEvent][val].split(":");
                if (tokens[1] == "number") {
                    metricsIndexArray.push(val);
                    metricsIndexMap[tokens[0]] = val;
                }

                if ("tid" == tokens[0]) {
                    tidRowIndex = val;
                }

                if ("duration" == tokens[0] || "runTime" == tokens[0]) { // TODO: take from user
                    spanIndex = val;
                }
                if ("timestamp" == tokens[0]) { // TODO: take from user
                    timestampIndex = val;
                }
                if (tokens[1] == "text" || tokens[1] == "timestamp") {
                    dimIndexMap[tokens[0]] = val;
                }
            }
            if (localContextData == undefined) {
                //support only tid or tn
                if (!(groupBySamples === "threadname" || groupBySamples === "tid")) {
                    //set default tid
                    groupBySamples = "tid";
                    if (eventType == "Jstack" || eventType == "json-jstack") {
                        updateFilterViewStatus("Note: Failed to get Request context, only tid and threadName group by options supported.");
                    } else {
                        updateFilterViewStatus("Note: Failed to get Request context, only tid group by option supported.");
                    }
                }
            }
            let contextDataRecords = undefined;
            if (localContextData != undefined && localContextData.records != undefined) {
                contextDataRecords = localContextData.records[samplesCustomEvent];
            }

            let tidDatalistVal = filterMap["tid"];

            if(getContextTree(1, eventType) == undefined){
                continue;
            }
            let contextTidMap = getContextTree(1, eventType).context.tidMap;
            let contextStart = getContextTree(1, eventType).context.start;

            if (eventType == "Jstack" || eventType == "json-jstack") {
                filteredStackMap[FilterLevel.LEVEL3] = {};
                isJstack=true;
            }
            //every sample of jstack has a tn
            let combinedEventKey = eventType + samplesCustomEvent;
            if ((eventType == "Jstack" || eventType == "json-jstack") && groupBySamples == "threadname" && isFilterEmpty(dimIndexMap)) {
                //for (var tid in contextDataRecords) {
                for (var tid in contextTidMap) {
                    if (tidDatalistVal == undefined || tidDatalistVal == tid) {
                        for (let i = 0; i < contextTidMap[tid].length; i++) {
                            if ((pStart == '' || pEnd == '') || (contextTidMap[tid][i].time + contextStart) >= pStart && (contextTidMap[tid][i].time + contextStart) <= pEnd) {//apply time range filter
                                if (isAll || (isWith && contextTidMap[tid][i][customEvent]?.obj != undefined) || (!isWith && contextTidMap[tid][i][customEvent]?.obj == undefined)) {
                                    let stack = contextTidMap[tid][i].hash;
                                    if (frameFilterString == "" || (frameFilterStackMap[combinedEventKey] != undefined && frameFilterStackMap[combinedEventKey][stack] !== undefined)) {

                                        if (tidSamplesTimestamps[tid] == undefined) {
                                            tidSamplesTimestamps[tid] = [];
                                        }
                                        if (isJstack) {
                                            tidSamplesTimestamps[tid].push([contextTidMap[tid][i].time + jstackdiff, jstackcolorsmap[contextTidMap[tid][i].ts], i, contextTidMap[tid][i][customEvent]?.obj[timestampIndex]]);
                                        } else {
                                            tidSamplesTimestamps[tid].push([contextTidMap[tid][i].time, tempeventTypeCount, i, contextTidMap[tid][i][customEvent]?.obj[timestampIndex]]);
                                        }
                                        eventSampleCount++;

                                        if (sampletableFormat == 0) {
                                            let key = contextTidMap[tid][i].tn;
                                            //consider
                                            if (sampleSortMap.has(key)) {
                                                sampleSortMap.set(key, sampleSortMap.get(key) + 1);
                                            } else {
                                                sampleSortMap.set(key, 1);
                                            }

                                            if (sampleCountMap.has(key)) {
                                                let tmpMap = sampleCountMap.get(key);
                                                if (tmpMap.has(stack)) {
                                                    tmpMap.set(stack, tmpMap.get(stack) + 1);
                                                } else {
                                                    tmpMap.set(stack, 1);
                                                }
                                            } else {
                                                let tmpMap = new Map();
                                                tmpMap.set(stack, 1);
                                                sampleCountMap.set(key, tmpMap);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                //every sample will have a tid, so include all
            } else if (groupBySamples == "tid" && isFilterEmpty()) {
                //for (var tid in contextDataRecords) {
                for (var tid in contextTidMap) {
                    if (tidDatalistVal == undefined || tidDatalistVal == tid) {
                        for (let i = 0; i < contextTidMap[tid].length; i++) {
                            if ((pStart == '' || pEnd == '') || (contextTidMap[tid][i].time + contextStart) >= pStart && (contextTidMap[tid][i].time + contextStart) <= pEnd) {//apply time range filter
                                if (isAll || (isWith && contextTidMap[tid][i][customEvent]?.obj != undefined) || (!isWith && contextTidMap[tid][i][customEvent]?.obj == undefined)) {
                                    let stack = contextTidMap[tid][i].hash;
                                    if (frameFilterString == "" || (frameFilterStackMap[combinedEventKey] != undefined && frameFilterStackMap[combinedEventKey][stack] !== undefined)) {

                                        if (tidSamplesTimestamps[tid] == undefined) {
                                            tidSamplesTimestamps[tid] = [];
                                        }
                                        if (isJstack) {
                                            tidSamplesTimestamps[tid].push([contextTidMap[tid][i].time + jstackdiff, jstackcolorsmap[contextTidMap[tid][i].ts], i, contextTidMap[tid][i][customEvent]?.obj[timestampIndex]]);
                                        } else {
                                            tidSamplesTimestamps[tid].push([contextTidMap[tid][i].time, tempeventTypeCount, i, contextTidMap[tid][i][customEvent]?.obj[timestampIndex]]);
                                        }
                                        eventSampleCount++;
                                        if (sampletableFormat == 0) {
                                            let key = tid;
                                            if (sampleSortMap.has(key)) {
                                                sampleSortMap.set(key, sampleSortMap.get(key) + 1);
                                            } else {
                                                sampleSortMap.set(key, 1);
                                            }
                                            if (sampleCountMap.has(key)) {
                                                let tmpMap = sampleCountMap.get(key);
                                                if (tmpMap.has(stack)) {
                                                    tmpMap.set(stack, tmpMap.get(stack) + 1);
                                                } else {
                                                    tmpMap.set(stack, 1);
                                                }
                                            } else {
                                                let tmpMap = new Map();
                                                tmpMap.set(stack, 1);
                                                sampleCountMap.set(key, tmpMap);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                //if only frame filter is selected then we need to include stacks that are any stack sample and containing frame filter string
            } else if (frameFilterString !== "" && isFilterEmpty()) {
                //for (var tid in contextDataRecords) {
                for (var tid in contextTidMap) {
                    if (tidDatalistVal == undefined || tidDatalistVal == tid) {
                        for (let i = 0; i < contextTidMap[tid].length; i++) {
                            if ((pStart == '' || pEnd == '') || (contextTidMap[tid][i].time + contextStart) >= pStart && (contextTidMap[tid][i].time + contextStart) <= pEnd) {//apply time range filter
                                if (isAll || (isWith && contextTidMap[tid][i][customEvent]?.obj != undefined) || (!isWith && contextTidMap[tid][i][customEvent]?.obj == undefined)) {
                                    let stack = contextTidMap[tid][i].hash;
                                    if ((frameFilterStackMap[combinedEventKey] != undefined && frameFilterStackMap[combinedEventKey][stack] !== undefined)) {

                                        if (tidSamplesTimestamps[tid] == undefined) {
                                            tidSamplesTimestamps[tid] = [];
                                        }
                                        if (isJstack) {
                                            tidSamplesTimestamps[tid].push([contextTidMap[tid][i].time + jstackdiff, jstackcolorsmap[contextTidMap[tid][i].ts], i, contextTidMap[tid][i][customEvent]?.obj[timestampIndex]]);
                                        } else {
                                            tidSamplesTimestamps[tid].push([contextTidMap[tid][i].time, tempeventTypeCount, i, contextTidMap[tid][i][customEvent]?.obj[timestampIndex]]);
                                        }
                                        eventSampleCount++;
                                        if (sampletableFormat == 0) {
                                            let key = "";
                                            if (contextTidMap[tid][i][samplesCustomEvent]?.obj != undefined) {
                                                key = contextTidMap[tid][i][samplesCustomEvent].obj[dimIndexMap[groupBySamples]];
                                            } else {
                                                key = "stacks matched frame but no context match";
                                            }
                                            if (key != undefined && key.slice != undefined) {
                                                key = key.slice(0, samplesgroupByLength);
                                            }
                                            //consider
                                            if (sampleSortMap.has(key)) {
                                                sampleSortMap.set(key, sampleSortMap.get(key) + 1);
                                            } else {
                                                sampleSortMap.set(key, 1);
                                            }
                                            if (sampleCountMap.has(key)) {
                                                let tmpMap = sampleCountMap.get(key);
                                                if (tmpMap.has(stack)) {
                                                    tmpMap.set(stack, tmpMap.get(stack) + 1);
                                                } else {
                                                    tmpMap.set(stack, 1);
                                                }
                                            } else {
                                                let tmpMap = new Map();
                                                tmpMap.set(stack, 1);
                                                sampleCountMap.set(key, tmpMap);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (localContextData != undefined && localContextData.records != undefined) {
                    if(isAll || isWith) {
                        for (var tid in contextDataRecords) {
                            if (tidDatalistVal == undefined || tidDatalistVal == tid) {
                                //context filter provided, check for matching requests and then find samples of those requests
                                contextDataRecords[tid].forEach(function (obj) {

                                    let record = obj.record;
                                    let flag = false;
                                    let recordSpan = record[spanIndex] == undefined ? 0 : record[spanIndex];

                                    if (filterMatch(record, dimIndexMap, timestampIndex, recordSpan)) {
                                        if (obj[combinedEventKey] != undefined) {
                                            flag = true;
                                            let key = record[dimIndexMap[groupBySamples]];
                                            if (key != undefined && key.slice != undefined) {
                                                key = key.slice(0, samplesgroupByLength);
                                            }
                                            //check if request samples match frame filter string
                                            let cursampleCount = 0;
                                            for (let i = obj[combinedEventKey][0]; i <= obj[combinedEventKey][1]; i++) {
                                                if ((pStart === '' || pEnd === '') || ((contextTidMap[tid][i].time + contextStart) >= pStart && (contextTidMap[tid][i].time + contextStart) <= pEnd)) {
                                                    if (isAll || (isWith && contextTidMap[tid][i][customEvent]?.obj != undefined) || (!isWith && contextTidMap[tid][i][customEvent]?.obj == undefined)) {
                                                        let stack = contextTidMap[tid][i].hash;
                                                        //for (var stack in obj[combinedEventKey]) {
                                                        if (frameFilterString == "" || (frameFilterStackMap[combinedEventKey] != undefined && frameFilterStackMap[combinedEventKey][stack] !== undefined)) {

                                                            if (tidSamplesTimestamps[tid] == undefined) {
                                                                tidSamplesTimestamps[tid] = [];
                                                            }
                                                            if (isJstack) {
                                                                tidSamplesTimestamps[tid].push([contextTidMap[tid][i].time + jstackdiff, jstackcolorsmap[contextTidMap[tid][i].ts], i, contextTidMap[tid][i][customEvent]?.obj[timestampIndex]]);
                                                            } else {
                                                                tidSamplesTimestamps[tid].push([contextTidMap[tid][i].time, tempeventTypeCount, i, contextTidMap[tid][i][customEvent]?.obj[timestampIndex]]);
                                                            }
                                                            eventSampleCount++;

                                                            cursampleCount++;

                                                            if (sampletableFormat == 0) {
                                                                if (sampleCountMap.has(key)) {
                                                                    let tmpMap = sampleCountMap.get(key);
                                                                    if (tmpMap.has(stack)) {
                                                                        tmpMap.set(stack, tmpMap.get(stack) + 1);
                                                                    } else {
                                                                        tmpMap.set(stack, 1);
                                                                    }
                                                                } else {
                                                                    let tmpMap = new Map();
                                                                    tmpMap.set(stack, 1);
                                                                    sampleCountMap.set(key, tmpMap);
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            if (sampletableFormat == 0) {
                                                if (cursampleCount != 0) {
                                                    if (sampleSortMap.has(key)) {
                                                        sampleSortMap.set(key, sampleSortMap.get(key) + cursampleCount);
                                                    } else {
                                                        sampleSortMap.set(key, cursampleCount);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                });
                            }
                        }
                    }else{
                        for (var tid in contextTidMap) {
                            if (tidDatalistVal == undefined || tidDatalistVal == tid) {
                                for (let i = 0; i < contextTidMap[tid].length; i++) {
                                    if ((pStart == '' || pEnd == '') || (contextTidMap[tid][i].time + contextStart) >= pStart && (contextTidMap[tid][i].time + contextStart) <= pEnd) {//apply time range filter
                                        if (isAll || (isWith && contextTidMap[tid][i][customEvent]?.obj != undefined) || (!isWith && contextTidMap[tid][i][customEvent]?.obj == undefined)) {
                                            let stack = contextTidMap[tid][i].hash;
                                            if (frameFilterString == "" || (frameFilterStackMap[combinedEventKey] != undefined && frameFilterStackMap[combinedEventKey][stack] !== undefined)) {

                                                if (tidSamplesTimestamps[tid] == undefined) {
                                                    tidSamplesTimestamps[tid] = [];
                                                }
                                                if (isJstack) {
                                                    tidSamplesTimestamps[tid].push([contextTidMap[tid][i].time + jstackdiff, jstackcolorsmap[contextTidMap[tid][i].ts], i, contextTidMap[tid][i][customEvent]?.obj[timestampIndex]]);
                                                } else {
                                                    tidSamplesTimestamps[tid].push([contextTidMap[tid][i].time, tempeventTypeCount, i, contextTidMap[tid][i][customEvent]?.obj[timestampIndex]]);
                                                }
                                                eventSampleCount++;
                                                if (sampletableFormat == 0) {
                                                    let key = tid;
                                                    if (sampleSortMap.has(key)) {
                                                        sampleSortMap.set(key, sampleSortMap.get(key) + 1);
                                                    } else {
                                                        sampleSortMap.set(key, 1);
                                                    }
                                                    if (sampleCountMap.has(key)) {
                                                        let tmpMap = sampleCountMap.get(key);
                                                        if (tmpMap.has(stack)) {
                                                            tmpMap.set(stack, tmpMap.get(stack) + 1);
                                                        } else {
                                                            tmpMap.set(stack, 1);
                                                        }
                                                    } else {
                                                        let tmpMap = new Map();
                                                        tmpMap.set(stack, 1);
                                                        sampleCountMap.set(key, tmpMap);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (eventType == "Jstack" || eventType == "json-jstack") {
                        updateFilterViewStatus("Note: Failed to get Request context, only tid and threadName group by options supported.");
                    } else {
                        updateFilterViewStatus("Note: Failed to get Request context, only tid group by option supported.");
                    }
                }
            }
            console.log("count " + eventType +":"+eventSampleCount + ":"+jfrprofilestart+":"+jstactprofilestart);
        }

        let start = performance.now();
        $("#sampletablecontext").html("");
        if (sampletableFormat == 1) {
            $('#extraoptions').hide();
            $("#sampletablecontext").css({"height":''});
            $('#stack-view-guid').text("");
            $('#stack-view-java-label-guid').text("Stack Trace");
            prevSampleReqCellObj = undefined;
            prevSampleReqCellSid = undefined;
            prevSampleReqCellTime = undefined;

            let matchedTidCount = 0;
            let tidSamplesCountMap = new Map(); //sort tid based on number of samples
            for (var tid in tidSamplesTimestamps) {
                tidSamplesCountMap.set(tid, tidSamplesTimestamps[tid].length);
                tidSamplesTimestamps[tid].sort((a, b) => a[0] - b[0]);
                matchedTidCount++;
            }
            tidSamplesCountMap = new Map([...tidSamplesCountMap.entries()].sort((a, b) => b[1] - a[1]));
            let isJstack = false;
            if((getEventType() == "Jstack" || getEventType() == "json-jstack") && $("#event-type-sample").val() != "All"){
                isJstack = true;
            }
            let top = 75;
            if(matchedTidCount < top){
                top = matchedTidCount+15;
            }else if(isJstack){
                top = matchedTidCount + 15;
            }
            let uniquetimestamps = generateTimestamseries(tidSamplesTimestamps,tidSamplesCountMap, top);
            $("#sampletable").html("");

            //sampletable
            let cellh = 8;
            let cellw = 4;
            let x = 20;
            let y = 10;

            if(isJstack){
                cellh = 8;
                cellw = 8;
            }

            document.getElementById("sampletable").innerHTML = "<div class='row col-lg-12' style='padding: 0px !important;'>"
                + "<div  style='width: 7%;float: left;'></div>"
                + "<div style=\"max-height: 50px;overflow: hidden;width: 93%;float: right;\">"
                + " <div class='row col-lg-12' style='padding: 0px !important;'>"
                + "   <div class='xaxisidSamples col-lg-12' id='xaxisidSamples' style=\"padding: 0px !important; max-height: 50px;overflow: scroll;overflow-y: hidden;\" onscroll='OnScroll1Samples(this)'>"
                + "   </div>"
                + " </div>"
                + "</div>"
                + "</div>"
                + "<div class='row col-lg-12' style='padding: 0px !important;'>"
                + " <div  id='yaxisidSamples' style=\"max-height: " + (top + 2) * cellh + "px;overflow: scroll;overflow-x: hidden;width: 7%;float: left;\" class='yaxisidSamples' onscroll='OnScroll0Samples(this)'></div>"
                + " <div id='requestbarchartSampleswrapper' style=\"max-height: " + (top + 2) * cellh + "px;overflow: hidden;width: 93%;float: right;\">"
                + "    <div class='row col-lg-12' style='padding: 0px !important;'>"
                + "      <div class='requestbarchartSamples col-lg-12' onscroll='OnScroll2Samples(this)' style=\"padding: 0px !important; height: " + (top + 2) * cellh + "px;max-height: " + (top + 2) * cellh + "px;overflow: auto;\" id='requestbarchartSamples'>"
                + "      </div>"
                + "    </div>"
                + " </div>"
                + "</div><div>Note: Top " + (top-15) + " threads sorted by number of samples</div>";

            d3.select("#requestbarchartSamples").append("svg").attr("width", (maxThreadSamples *cellw)+37).attr("height", (top+2)*cellh);
            d3.select("#yaxisidSamples").append("svg").attr("width", 50).attr("height", (top+2)*cellh);
            d3.select("#xaxisidSamples").append("svg").attr("width",  (maxThreadSamples *cellw)+37).attr("height", 10);

            let d3yaxis = d3.select('#yaxisidSamples').select("svg");
            let d3xaxis = d3.select('#xaxisidSamples').select("svg");
            let d3svg = d3.select("#requestbarchartSamples").select("svg");

            let layer1 = d3svg.append('g');
            let layer2 = d3svg.append('g');
            let count = 0;
            let minTimeStamp = 0;
            let maxTimeStamp = 0;

            let xinterval = 80;
            let intervalcount = 0;
            for (let [timestamp, check] of uniquetimestamps) {
                if((intervalcount % xinterval) == 0) {
                    d3xaxis.append("text")
                        .text(moment.utc(jfrprofilestart+timestamp).format('HH:mm:ss'))//moment.utc(d * downScale + contextStart).format('MM-DD HH:mm:ss');
                        .attr("x", intervalcount + x)
                        .style("font-size", "10px")
                        .attr("y", 10);
                }
                intervalcount++;
            }

            for (let [tid, value] of tidSamplesCountMap) {
                if (count < top) {
                    count++;
                    d3yaxis.append("text")
                        .text(tid)
                        .attr("x", 15)
                        .style("font-size", cellh+"px")
                        .attr("y", y+cellh);

                    layer1.append('line')
                        .style('stroke-dasharray', [2,1])
                        .style('stroke', '#E2E2E2')
                        .attr('x1', x)
                        .attr('y1', y+cellh/2 )
                        .attr('x2', maxThreadSamples*cellh)
                        .attr('y2', y+cellh/2);

                    let i = 0;
                    //console.log("total len:" + tidSamplesTimestamps[tid].length);
                    let dupCount = 0;
                    let prevx = -1;
                    let lastx = -1;
                    let prevt = -1;
                    for (let [timestamp, check] of uniquetimestamps) {


                        if (i < tidSamplesTimestamps[tid].length) {
                            if (check == -1) {
                                //put a dash rect
                            } else if (timestamp == tidSamplesTimestamps[tid][i][0]) {
                                if(minTimeStamp == 0){
                                    minTimeStamp = timestamp;
                                }
                                if(timestamp > maxTimeStamp) {
                                    maxTimeStamp = timestamp;
                                }
                                //put color rect
                                //handle duplicates
                                if(timestamp == tidSamplesTimestamps[tid][i][0]) {
                                    layer2.append("rect")
                                        .attr("width", cellw)
                                        .attr("height", cellh)
                                        .attr("x", x)
                                        .attr("y", y)
                                        .attr("e", tidSamplesTimestamps[tid][i][1])
                                        .attr("t", tid)
                                        .attr("in", tidSamplesTimestamps[tid][i][2])
                                        .attr("class", " tgl")
                                        .attr("onclick", 'showSVGSampleStack(evt)')
                                        .attr("fill", getSampleColor(tidSamplesTimestamps[tid][i][1]));

                                    if(prevx == -1){
                                        if (tidSamplesTimestamps[tid][i][3] != undefined) {
                                            lastx = x;
                                            prevx = x;
                                        }
                                    }else {
                                        if (tidSamplesTimestamps[tid][i][3] == undefined) {
                                            if ((prevx - lastx) > 1) {
                                                layer1.append('line')
                                                    .style('stroke-width', 0.5)
                                                    .style('stroke', 'red')
                                                    .attr('skip', true)
                                                    .attr('x1', lastx)
                                                    .attr('y1', y+cellh/2)
                                                    .attr('x2', prevx+cellw)
                                                    .style("opacity",0.5)
                                                    .attr('y2', y+cellh/2);
                                            }
                                            prevx=-1;
                                        } else if (tidSamplesTimestamps[tid][i][3] != undefined && prevt != tidSamplesTimestamps[tid][i][3]) {
                                            //draw line
                                            if ((prevx - lastx) > 1) {
                                                layer1.append('line')
                                                    .style('stroke-width', 0.5)
                                                    .style('stroke', 'red')
                                                    .attr('skip', true)
                                                    .attr('x1', lastx)
                                                    .attr('y1', y+cellh/2)
                                                    .attr('x2', prevx+cellw)
                                                    .attr('y2', y+cellh/2)
                                                    .style("opacity",0.5);
                                            }
                                            lastx = x;
                                        }else if (tidSamplesTimestamps[tid][i][3] != undefined) {
                                            prevx = x;
                                        }
                                    }
                                    prevt = tidSamplesTimestamps[tid][i][3];

                                    i++;

                                }
                                while(i < tidSamplesTimestamps[tid].length && timestamp == tidSamplesTimestamps[tid][i][0]) {
                                    i++;
                                    dupCount++;
                                }
                            }
                        } else {
                            //put a whitc rect
                        }
                        x += cellw;
                    }

                    //console.log("matched len:" + i + " dup:"+dupCount);
                    x = 20;
                    y += cellh;
                }
            }
            let requiredWidth = (uniquetimestamps.size*cellw+37 > 500)? uniquetimestamps.size*cellw+37 : 500;
            d3svg.style('width',requiredWidth);
            if(y > 700){
                y = 700;
            }
            $("#yaxisidSamples").css({"max-height":y});
            $("#requestbarchartSampleswrapper").css({"max-height":y+30});
            $("#requestbarchartSamples").css({"max-height":y+30});
        } else {
            $('#extraoptions').show();
            $("#sampletablecontext").css({"height":''});
            //sort based on number of stacks
            for (let [key, value] of sampleCountMap) {
                sampleCountMap.set(key, new Map([...value.entries()].sort((a, b) => b[1] - a[1])));
            }

            sampleSortMap = new Map([...sampleSortMap.entries()].sort((a, b) => b[1] - a[1]));


            let end1 = performance.now();
            console.log("genSampleTable 0 time:" + (end1 - start1))

            let order = 1;

            moreSamples = {};
            for (let [key, value] of sampleSortMap) {

                if ((samplesgroupByMatch != '' && key.includes != undefined && !key.includes(samplesgroupByMatch))) {
                    continue;
                }

                let str = "";
                let more = "";
                let morec = 0;
                let skipc = 0;
                let count = 0;
                let order = 0;
                samplerowIndex++;

                for (let [key1, value1] of sampleCountMap.get(key)) {
                    if (count < 8) {
                        if (order == 0) {
                            order = value1;
                        }
                        str = str + "<div style=\" cursor: pointer;\" data-ga-category=\"samples-table\" data-ga-action=\"show-stack\" id=\"+ key1 + \" class=\"send-ga stack-badge badge badge-secondary  stack" + key1 + "\" onclick=\"showSampleStack('" + key1 + "');\">" + (100 * value1 / value).toFixed(2) + "%, " + value1 + "</div> &nbsp;";
                    } else {
                        if (morec < 25) {
                            morec++;
                            more = more + "<div style=\"display: none; cursor: pointer; \"   class=\"stack-badge badge badge-secondary  stack" + key1 + " hidden-stacks-" + hashCode(key) + "\" onclick=\"showSampleStack('" + key1 + "');\">" + (100 * value1 / value).toFixed(2) + "%, " + value1 + "</div>&nbsp;";
                        } else {
                            skipc++;
                        }
                    }
                    count++;
                }
                if (morec != 0) {
                    moreSamples[key] = more;
                    str += '<div style="cursor: pointer;" class="badge badge-primary more-stacks-' + hashCode(key) + '" onclick="showHiddenStacks(\'' + hashCode(key) + '\');"> +' + (morec + skipc) + ' more</div>';
                    str += '<div style="cursor: pointer; display: none;" class="badge badge-primary less-stacks-' + hashCode(key) + '" onclick="hideHiddenStacks(\'' + hashCode(key) + '\');"> << </div> ';
                    str += more;
                    str += '<div style="cursor: pointer; display: none;" class="badge badge-primary less-stacks-' + hashCode(key) + '" onclick="hideHiddenStacks(\'' + hashCode(key) + '\');"> -' + morec + ' less</div> ';
                    if (skipc != 0) {
                        str += "<div style=\"display: none;\"   class=\"stack-badge badge " + " hidden-stacks-" + hashCode(key) + "\"\">" + skipc + " more</div>";
                    }
                }
                sampleTableRows[samplerowIndex] = [];
                /*if(eventType == EventType.MEMORY) {
                    addContextTableRow(sampleTableRows[samplerowIndex], ("<label style=\"word-wrap: break-word; width: 300px\" >" + (key == undefined ? "NA" : key) + "</label>"), "hint='"+groupBySamples+"'");
                    addContextTableOrderRow(sampleTableRows[samplerowIndex], ("<b>" + (value / (1024 * 1024)).toFixed(3) + "</b>&nbsp;<div class=\"badge badge-info\"> " + (100 * value / totalSampleCount).toFixed(3) + "</div>"), value);
                    addContextTableOrderRow(sampleTableRows[samplerowIndex], str, order);
                }else{*/

                //"id='"+Number(dim) + "_dummy'"
                if (groupBySamples == "tid") {
                    sfSampleTable.addContextTableRow(sampleTableRows[samplerowIndex], ("<div style=\"cursor: pointer; word-wrap: break-word;\" >" + (key == undefined ? "NA" : key) + "</div>"), "id='" + key + "_dummy'" + " hint='" + groupBySamples + "'");
                } else {
                    sfSampleTable.addContextTableRow(sampleTableRows[samplerowIndex], ("<div style=\"cursor: pointer; word-wrap: break-word;\" >" + (key == undefined ? "NA" : key) + "</div>"), "hint='" + groupBySamples + "'");
                }
                sfSampleTable.addContextTableOrderRow(sampleTableRows[samplerowIndex], ("<div class=\"badge badge-info\"><span style='font-size: 12px; color:black'>" + value + "</span> " + (100 * value / totalSampleCount).toFixed(3) + "%</div>"), value);
                sfSampleTable.addContextTableOrderRow(sampleTableRows[samplerowIndex], str, order);

                // }
                //table = table + "<tr><td  hint=" + groupBySamples + " class=\"context-menu-two\"><label style=\"word-wrap: break-word; width: 300px\" >" + (key == undefined ? "NA" : key) + "</label></td><td data-order="+value+"><b>" +value+"</b>&nbsp;<div class=\"badge badge-info\"> "+ (100*value/totalSampleCount).toFixed(3) + "</div></td><td data-order="+order+">" + str + "</td></tr>";
            }

            sfSampleTable.SFDataTable(sampleTableRows, sampleTableHeader, "sampletable", order);

        }

        if(addContext) {
            updateEventInputOptions('event-input-smpl');
            updateGroupByOptions('smpl-grp-by');
            updateSampleFormatOptions('sample-format-input');

            if(stack_id != '' && sampletableFormat == 0){
                showSampleStack(stack_id);
            }
        }

        let end = performance.now();
        console.log("genSampleTable 1 time:" + (end - start) )
    }

    function OnScroll0Samples(div) {
        var d2 = document.getElementById("requestbarchartSamples");
        d2.scrollTop = div.scrollTop;
    }

    function OnScroll1Samples(div) {
        var d2 = document.getElementById("requestbarchartSamples");
        d2.scrollLeft = div.scrollLeft;
    }

    function OnScroll2Samples(div) {
        var d1 = document.getElementById("xaxisidSamples");
        var d0 = document.getElementById("yaxisidSamples");
        d0.scrollTop = div.scrollTop;
        d1.scrollLeft = div.scrollLeft;
    }


    var TooltipTSV = undefined;
    var mouseoverSVGSamples = function (key, obj) {
        if (d3.select(obj).attr("style") == undefined || !d3.select(obj).attr("style").includes("opacity: 0")) {

            //TooltipTSV.style("opacity", 1);

            d3.select(obj)
                .style("stroke", "black")
                .style("cursor", "pointer");
        }
    }

    var mousemoveSVGSamples = function (d, key, obj, metricVal) {
        if (d3.select(obj).attr("style") == undefined || !d3.select(obj).attr("style").includes("opacity: 0")) {
            /*TooltipTSV
                .html(d + ", " + metricVal + '<br>Click to see request profile samples and context')
                .style("left", (d3.mouse(obj)[0] + 20) + "px")
                .style("top", (d3.mouse(obj)[1]) + "px");*/
        }
    }

    var mouseleaveSVGSamples = function (key, obj) {
        if (d3.select(obj).attr("style") == undefined || !d3.select(obj).attr("style").includes("opacity: 0")) {
            //TooltipTSV.style("opacity", 0);
            d3.select(obj)
                .style("stroke", "none")
                .style("cursor", "default");
        }
    }

    let prevSampleReqCellObj = undefined;
    let prevSampleReqCellSid = undefined;
    let prevSampleReqCellTime = undefined;
    const sfSamplecontextTable = new SFDataTable("sampletablecontext");
    Object.freeze(sfSamplecontextTable);

    function showSampleContextTable(record, event) {
        let rowIndex = 0;
        sampleTableHeader = [];
        sampleTableRows = [];
        getContextTableHeadernew("", sampleTableHeader, customEvent, false);
        sampleTableRows[rowIndex] = [];
        if(record.length == 0){
            sfSamplecontextTable.addContextTableRow(sampleTableRows[rowIndex], "no context available");
        }else {
            for (let field in record) {
                if (field == 1) {
                    sfSamplecontextTable.addContextTableRow(sampleTableRows[rowIndex], moment.utc(record[field]).format('YYYY-MM-DD HH:mm:ss SSS'));
                } else {
                    sfSamplecontextTable.addContextTableRow(sampleTableRows[rowIndex], record[field]);
                }
            }
        }
        sfSamplecontextTable.SFDataTable(sampleTableRows, sampleTableHeader, "sampletablecontext", undefined, false);
    }

    function showSVGSampleStack(obj) {
        document.getElementById('SampleprofileID').focus();
        let tempeventTypeArray = [];
        let jevent = "json-jstack";
        for (var tempeventType in jfrprofiles1) {//for all profile event types
            tempeventTypeArray.push(tempeventType);
            if(tempeventType == "Jstack"){
                jevent = "Jstack";
            }
        }
        tempeventTypeArray.sort();

        let pid = obj.target.getAttribute("t");
        let eventType = ""
        if(obj.target.getAttribute("e") > 8){
            eventType = jevent;
        }else {
            eventType = tempeventTypeArray[obj.target.getAttribute("e")];
        }

        let index = obj.target.getAttribute("in");

        if(contextTree1[eventType].context.tidMap[pid][index][customEvent] != undefined && contextTree1[eventType].context.tidMap[pid][index][customEvent].obj != undefined){
            showSampleContextTable(contextTree1[eventType].context.tidMap[pid][index][customEvent].obj, eventType);
        }else{
            if($("#sampletablecontext").height() != 0) {
                $("#sampletablecontext").css("height", $("#sampletablecontext").height());
            }
            showSampleContextTable([], eventType);
        }

        let stackid = contextTree1[eventType].context.tidMap[pid][index].hash;

        if(prevSampleReqCellObj != undefined) {
            prevSampleReqCellObj.classList.remove('stackCells');
        }
        prevSampleReqCellObj = obj.target;
        prevSampleReqCellSid = stackid;
        prevSampleReqCellTime = contextTree1[eventType].context.tidMap[pid][index].time + contextTree1[eventType].context.start;
        prevSampleReqCellObj.classList.add('stackCells');

        updateUrl("stack_id",stackid,true);
        stack_id=stackid;
        $('#stack-view-java-label-guid').text("Stack Trace at " + moment.utc(prevSampleReqCellTime).format('YYYY-MM-DD HH:mm:ss.SSS'));
        $('#stack-view-guid').text(getStackTrace(stackid, eventType,obj.target.getAttribute("e"), prevSampleReqCellTime));
    }

    function getSampleColor(id){
        return profilecolors[id];
    }

    let maxThreadSamples=0;
    let minThreadSamplesTimeStamp = 0;
    let maxThreadSamplesTimeStamp = 0;
    function generateTimestamseries(tidSamplesTimestamps,tidSamplesCountMap, top){

        let tmpTimestampap = new Map();
        let timestampArray = [];

        let start = performance.now();

        //generate unique timestamp array
        let count = 0;
        for (let [tid, value] of tidSamplesCountMap) {
            if (count < top) {
                count++;
                for (let i = 0; i < tidSamplesTimestamps[tid].length; i++) {
                    if (!tmpTimestampap.hasOwnProperty(tidSamplesTimestamps[tid][i][0])) {
                        tmpTimestampap.set(tidSamplesTimestamps[tid][i][0], true);
                        timestampArray.push(tidSamplesTimestamps[tid][i][0]);
                    }
                }
            }
        }
        timestampArray.sort(function (a, b) {
            return a - b
        });
        let prev = timestampArray[0];
        count = 0;
        for(let i = 0; i<timestampArray.length; i++){
            if((timestampArray[i]-prev) > 60000){
                tmpTimestampap.set(Math.round((timestampArray[i]+prev)/2),-1);
                count++;
            }
            tmpTimestampap.set(timestampArray[i], i);
            prev = timestampArray[i];
            count++;
        }
        let end = performance.now();
        console.log("generateTimestamseries time :" + (end - start));
        maxThreadSamples = count;
        minThreadSamplesTimeStamp = timestampArray[0];
        maxThreadSamplesTimeStamp = timestampArray[timestampArray.length-1];
        console.log("unique timestamps length:" + timestampArray.length);
        tmpTimestampap = new Map([...tmpTimestampap.entries()].sort((a, b) => a[0] - b[0]));
        return tmpTimestampap;
    }


    function showHiddenStacks(guid) {
        $(".more-stacks-" + guid).css("display", "none");
        $(".less-stacks-" + guid).css("display", "");
        $(".hidden-stacks-" + guid).css("display", "");
    }

    function hideHiddenStacks(guid) {
        $(".more-stacks-" + guid).css("display", "");
        $(".less-stacks-" + guid).css("display", "none");
        $(".hidden-stacks-" + guid).css("display", "none");
    }

    function getEventOfStackID(id){
        for (var profile in jfrprofiles1) {
            let tree = getContextTree(1,profile);
            if(tree != undefined && tree.tree != undefined && tree.tree.sm[id] != undefined){
                return profile;
            }
        }
        return getEventType();//default
    }

    function showSampleStack(stackid) {
        updateUrl("stack_id",stackid,true);
        stack_id=stackid;
        $('#stack-view-guid').text(getStackTrace(stackid,getEventOfStackID(stackid)));
        $('.stack-badge').removeClass("badge-warning");
        $(".stack"+stackid).addClass("badge-warning");
    }

    //create html tree recursively
    let prevSampleProfile = undefined;
    function updateProfilerViewSample(level, skipFilter) {
        addTabNote(false,"");
        let eventType = getEventType();

        let contextData = getContextData(1);
        if(contextData == undefined) {
            if(compareTree){
                addTabNote(true,"This view is not supported when Compare option is selected.")
            }else{
                addTabNote(true,"Context data not available to show this view");
            }
            console.log("updateProfilerViewSample skip:" + level);
            return false;
        }

        updateEventInputOptions('event-input-smpl');
        updateGroupByOptions('smpl-grp-by');
        updateSampleFormatOptions('sample-format-input');

        if(skipFilter == undefined){
            skipFilter = false;
        }

        showTimelineView(false);

        if(!skipFilter) {

            if (level == undefined) {
                level = FilterLevel.LEVEL1;
            }

            let start = performance.now();
            if (!filterToLevel(level)) {
                let end = performance.now();
                console.log("filterToLevel time:" + (end - start));
                return;
            }
            let end = performance.now();
            console.log("filterToLevel time:" + (end - start));


            let treeToProcess = getActiveTree(eventType, isCalltree);
            let selectedLevel = getSelectedLevel(getActiveTree(eventType, false));

            if (prevSampleProfile != "All" && prevCustomEvent === customEvent && currentLoadedTree === treeToProcess && prevOption === currentOption && isRefresh === false && isLevelRefresh === false && prevSelectedLevel === selectedLevel) {
                console.log("no change in sample table, option:" + (prevCustomEvent == customEvent) + ":" + (currentLoadedTree === treeToProcess)+":"+ (prevOption === currentOption) +" isRefresh:"+(isRefresh === false)+":"+" isLevelRefresh:"+(isLevelRefresh === false)+" selectedLevel:"+ (prevSelectedLevel === selectedLevel));
                end = performance.now();
                console.log("updateProfilerViewSample 1 time:" + (end - start));
                return;
            }else{
                console.log("change in sample table, option:" + prevSampleProfile +":"+ (prevCustomEvent == customEvent) + ":" + (currentLoadedTree === treeToProcess)+":"+ (prevOption === currentOption) +" isRefresh:"+(isRefresh === false)+":"+" isLevelRefresh:"+(isLevelRefresh === false)+" selectedLevel:"+ (prevSelectedLevel === selectedLevel));
            }
            currentLoadedTree = treeToProcess;
            prevOption = currentOption;
            prevCustomEvent = customEvent;
            prevSelectedLevel = selectedLevel;
            isLevelRefresh = false;
            isRefresh = false;
            prevSampleProfile = $("#event-type-sample").val();

            // if no data returned from our call don't try to parse it
            if (treeToProcess === undefined) {
                end = performance.now();
                console.log("updateProfilerViewSample 2 time:" + (end - start));
                return;
            }

            resetTreeHeader("");

            genSampleTable(true, level);

            end = performance.now();
            console.log("updateProfilerViewSample 3 time:" + (end - start));
        }else{
            prevSampleProfile = $("#event-type-sample").val();

            let start = performance.now();

            resetTreeHeader("");

            genSampleTable(true, level);

            let end = performance.now();
            console.log("updateProfilerViewSample 4 time:" + (end - start));

            if(!isFilterOnType){
                addTabNote(true,getContextHintNote(true,customEvent));
            }
        }
    }

    function hashCode(str) { // java String#hashCode
        if (str === undefined || str === null) {
            str = "";
        }
        var hash = 0;
        for (var i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash);
        }
        return hash;
    }

</script>