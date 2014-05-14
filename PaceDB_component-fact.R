#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Extract the component(WBS) fact data
# 2014/5/11
# Yasutaka Shirai

source("C:/doc/networkdays.R") # need to specify absolute path

m<-dbDriver("MySQL"); # set up the driver for reading the database

MydbName <- "tsppacedb" # database name
MyName <- "root" # database user
MyPass <- "i92slh" # database user password
OutputFile <- "component_fact.csv" # file name for output
PaperSize <- "a4r" # pdf size
NoData <- "No Data"

#Connect and authenticate to a MySQL database
con<-dbConnect(m,user=MyName,password=MyPass,host='localhost',dbname=MydbName);

# extract basic data
tab_component_info<-dbGetQuery(con,"select distinct wbs_element.wbs_element_key, replace(wbs_element_name, \",\",\".\") as wbs_element_name, project_key from tsppacedb.plan_item right join tsppacedb.wbs_element on tsppacedb.plan_item.wbs_element_key = tsppacedb.wbs_element.wbs_element_key where tsppacedb.wbs_element.wbs_element_key != 1 order by wbs_element_key")
tab_process_info<-dbGetQuery(con,"select distinct wbs_element_key,tsppacedb.phase.process_key,process_name from tsppacedb.plan_item left join tsppacedb.phase on tsppacedb.plan_item.phase_key = tsppacedb.phase.phase_key left join tsppacedb.process on tsppacedb.phase.process_key = tsppacedb.process.process_key where tsppacedb.phase.process_key is not null and wbs_element_key != 1 group by wbs_element_key")
#tab_teams_info<-dbGetQuery(con,"select distinct wbs_element_key, tsppacedb.data_block.team_key, team_name, person_key from tsppacedb.task_status_fact_hist left join tsppacedb.plan_item on tsppacedb.task_status_fact_hist.plan_item_key = tsppacedb.plan_item.plan_item_key left join tsppacedb.data_block on tsppacedb.task_status_fact_hist.data_block_key = tsppacedb.data_block.data_block_key left join tsppacedb.team on tsppacedb.data_block.team_key = tsppacedb.team.team_key where wbs_element_key != 1 order by wbs_element_key")
tab_teams_info<-dbGetQuery(con,"select distinct wbs_element_key, tsppacedb.data_block.team_key, REPLACE(team_name, \",\", \".\") as team_name, person_key from tsppacedb.task_status_fact_hist left join tsppacedb.plan_item on tsppacedb.task_status_fact_hist.plan_item_key = tsppacedb.plan_item.plan_item_key left join tsppacedb.data_block on tsppacedb.task_status_fact_hist.data_block_key = tsppacedb.data_block.data_block_key left join tsppacedb.team on tsppacedb.data_block.team_key = tsppacedb.team.team_key where wbs_element_key != 1 order by wbs_element_key")
tab_component_duration<-dbGetQuery(con, "select min(time_log_start_date) as start_date, max(time_log_end_date) as end_date,wbs_element_key from tsppacedb.time_log_fact_hist join tsppacedb.plan_item_hist on tsppacedb.time_log_fact_hist.plan_item_key = tsppacedb.plan_item_hist.plan_item_key where time_log_fact_key != 23000 and wbs_element_key != 1 group by wbs_element_key order by wbs_element_key")
tab_time_info<-dbGetQuery(con,"select wbs_element_key,phase_short_name,sum(task_actual_time_minutes) as sum_actual_time,sum(task_plan_time_minutes) as sum_plan_time,phase_type from tsppacedb.task_status_fact_hist left join tsppacedb.plan_item_hist on tsppacedb.task_status_fact_hist.plan_item_key = tsppacedb.plan_item_hist.plan_item_key left join tsppacedb.phase on tsppacedb.plan_item_hist.phase_key = tsppacedb.phase.phase_key where wbs_element_key != 1 group by wbs_element_key,phase_short_name order by wbs_element_key")
tab_ev_info<-dbGetQuery(con,"select wbs_element_key,task_actual_time_minutes,task_plan_time_minutes,task_actual_complete_date_key,task_date_key from tsppacedb.task_status_fact_hist left join tsppacedb.task_date_fact_hist on tsppacedb.task_status_fact_hist.plan_item_key = tsppacedb.task_date_fact_hist.plan_item_key left join tsppacedb.plan_item_hist on tsppacedb.task_status_fact_hist.plan_item_key = tsppacedb.plan_item_hist.plan_item_key where wbs_element_key != 1 group by wbs_element_key")
tab_bcws_info<-dbGetQuery(con,"SELECT wbs_element_key, SUM(s.task_plan_time_minutes) as sum_plan_minutes FROM task_status_fact s, task_date_fact d, measurement_type t, plan_item_hist h WHERE s.plan_item_key = d.plan_item_key AND s.data_block_key = d.data_block_key AND d.measurement_type_key = t.measurement_type_key AND t.measurement_type_name = 'Plan' AND d.task_date_key <= 29991231 AND s.plan_item_key = h.plan_item_key group by wbs_element_key")
tab_size_info<-dbGetQuery(con, "select wbs_element_key,measurement_type_key,size_metric_name,sum(size_added_and_modified) as sum_size_am,sum(size_added) as sum_size_added,sum(size_base) as sum_size_base,sum(size_deleted) as sum_size_deleted,sum(size_modified) as sum_size_modified,sum(size_reused) as sum_size_reused,sum(size_total) as sum_size_total from tsppacedb.size_fact_hist join tsppacedb.plan_item_hist on tsppacedb.size_fact_hist.plan_item_key = tsppacedb.plan_item_hist.plan_item_key join tsppacedb.size_metric on tsppacedb.size_fact_hist.size_metric_key = tsppacedb.size_metric.size_metric_key group by wbs_element_key,measurement_type_key,tsppacedb.size_fact_hist.size_metric_key");
tab_defect_injected_info<-dbGetQuery(con,"select wbs_element_key,sum(defect_fix_count) as sum_defect_fix_count,count(defect_log_fact_key) as sum_defect_records ,phase_short_name as defect_injected_phase_name from tsppacedb.defect_log_fact_hist left join tsppacedb.plan_item_hist on tsppacedb.defect_log_fact_hist.plan_item_key = tsppacedb.plan_item_hist.plan_item_key left join tsppacedb.phase on tsppacedb.defect_log_fact_hist.defect_injected_phase_key = tsppacedb.phase.phase_key where wbs_element_key != 1 group by wbs_element_key,defect_injected_phase_key")
tab_defect_removed_info<-dbGetQuery(con,"select wbs_element_key,sum(defect_fix_count) as sum_defect_fix_count,count(defect_log_fact_key) as sum_defect_records ,phase_short_name as defect_removed_phase_name from tsppacedb.defect_log_fact_hist left join tsppacedb.plan_item_hist on tsppacedb.defect_log_fact_hist.plan_item_key = tsppacedb.plan_item_hist.plan_item_key left join tsppacedb.phase on tsppacedb.defect_log_fact_hist.defect_removed_phase_key = tsppacedb.phase.phase_key where wbs_element_key != 1 group by wbs_element_key,defect_removed_phase_key")
tab_defect_fix_time_info<-dbGetQuery(con,"select wbs_element_key,tsppacedb.plan_item.phase_key,phase_short_name,sum(defect_fix_time_minutes) as sum_defect_fix_time from tsppacedb.defect_log_fact_hist left join tsppacedb.plan_item on tsppacedb.defect_log_fact_hist.plan_item_key = tsppacedb.plan_item.plan_item_key left join tsppacedb.phase on tsppacedb.plan_item.phase_key = tsppacedb.phase.phase_key group by wbs_element_key,phase_key order by wbs_element_key")

## Extract all WBS element key from WBS element table in the TSP Warehouse 
component_elements <- unique(tab_component_info$wbs_element_key)

## Open CSV file and create header
out <- file(OutputFile, "w")
writeLines(paste("WBS element key"), out, sep=",")
writeLines(paste("Organization name"), out, sep=",")
writeLines(paste("WBS element name"), out, sep=",")
writeLines(paste("project"), out, sep=",")
writeLines(paste("team key"), out, sep=",")
writeLines(paste("team size"), out, sep=",")
writeLines(paste("individuals"), out, sep=",")
writeLines(paste("process"), out, sep=",")
writeLines(paste("phase"), out, sep=",")
writeLines(paste("top phase"), out, sep=",")
writeLines(paste("bottom phase"), out, sep=",")
writeLines(paste("top and bottom phases"), out, sep=",")
writeLines(paste("Mean Team Task Hours Per Week"), out, sep=",")
writeLines(paste("Mean Team Member Task Hours Per Week"), out, sep=",")
writeLines(paste("Time Benford MAD"), out, sep=",")
writeLines(paste("Defect Benford MAD"), out, sep=",")
writeLines(paste("start date"), out, sep=",")
writeLines(paste("end date"), out, sep=",")
writeLines(paste("plan date"), out, sep=",")
writeLines(paste("baseline date"), out, sep=",")
writeLines(paste("predicted date"), out, sep=",")
writeLines(paste("start week"), out, sep=",")
writeLines(paste("actual week"), out, sep=",")
writeLines(paste("plan weeks"), out, sep=",")
writeLines(paste("baseline weeks"), out, sep=",")
writeLines(paste("growth schedule baseline to plan"), out, sep=",")
writeLines(paste("duration"), out, sep=",")
writeLines(paste("actual task hours"), out, sep=",")
writeLines(paste("plan task hours"), out, sep=",")
writeLines(paste("baseline task hours"), out, sep=",")
writeLines(paste("project completed parts plan hours"), out, sep=",")
writeLines(paste("project completed parts actual hours"), out, sep=",")
writeLines(paste("growth in task hours baseline to plan"), out, sep=",")
writeLines(paste("task estimation accuracy"), out, sep=",")
#writeLines(paste("CPI"), out, sep=",")
#writeLines(paste("SPI"), out, sep=",")
#writeLines(paste("CV"), out, sep=",")
#writeLines(paste("SV"), out, sep=",")
#writeLines(paste("CumPV"), out, sep=",")
#writeLines(paste("CumEV"), out, sep=",")
#writeLines(paste("Final EV"), out, sep=",")
writeLines(paste("planB"), out, sep=",")
writeLines(paste("planD"), out, sep=",")
writeLines(paste("planM"), out, sep=",")
writeLines(paste("planA"), out, sep=",")
writeLines(paste("planR"), out, sep=",")
writeLines(paste("planN"), out, sep=",")
writeLines(paste("planT"), out, sep=",")
writeLines(paste("planNR"), out, sep=",")
writeLines(paste("actualB"), out, sep=",")
writeLines(paste("actualD"), out, sep=",")
writeLines(paste("actualM"), out, sep=",")
writeLines(paste("actualA"), out, sep=",")
writeLines(paste("actualR"), out, sep=",")
writeLines(paste("actualN"), out, sep=",")
writeLines(paste("actualT"), out, sep=",")
writeLines(paste("actualNR"), out, sep=",")
writeLines(paste("PDIPLAN"), out, sep=",")
writeLines(paste("PDIREQ"), out, sep=",")
writeLines(paste("PDISTP"), out, sep=",")
writeLines(paste("PDIREQINSP"), out, sep=",")
writeLines(paste("PDIHLD"), out, sep=",")
writeLines(paste("PDIITP"), out, sep=",")
writeLines(paste("PDIHLDINSP"), out, sep=",")
writeLines(paste("PDIDLD"), out, sep=",")
writeLines(paste("PDIDLDR"), out, sep=",")
writeLines(paste("PDITD"), out, sep=",")
writeLines(paste("PDIDLDINSP"), out, sep=",")
writeLines(paste("PDICODE"), out, sep=",")
writeLines(paste("PDICR"), out, sep=",")
writeLines(paste("PDICOMPILE"), out, sep=",")
writeLines(paste("PDIINSP"), out, sep=",")
writeLines(paste("PDIUT"), out, sep=",")
writeLines(paste("PDIBIT"), out, sep=",")
writeLines(paste("PDIST"), out, sep=",")
writeLines(paste("PDIAT"), out, sep=",")
writeLines(paste("PDIPL"), out, sep=",")
writeLines(paste("PDITOTAL"), out, sep=",")
writeLines(paste("ADIPLAN"), out, sep=",")
writeLines(paste("ADIREQ"), out, sep=",")
writeLines(paste("ADISTP"), out, sep=",")
writeLines(paste("ADIREQINSP"), out, sep=",")
writeLines(paste("ADIHLD"), out, sep=",")
writeLines(paste("ADIITP"), out, sep=",")
writeLines(paste("ADIHLDINSP"), out, sep=",")
writeLines(paste("ADIDLD"), out, sep=",")
writeLines(paste("ADIDLDR"), out, sep=",")
writeLines(paste("ADITD"), out, sep=",")
writeLines(paste("ADIDLDINSP"), out, sep=",")
writeLines(paste("ADICODE"), out, sep=",")
writeLines(paste("ADICR"), out, sep=",")
writeLines(paste("ADICOMPILE"), out, sep=",")
writeLines(paste("ADIINSP"), out, sep=",")
writeLines(paste("ADIUT"), out, sep=",")
writeLines(paste("ADIBIT"), out, sep=",")
writeLines(paste("ADIST"), out, sep=",")
writeLines(paste("ADIAT"), out, sep=",")
writeLines(paste("ADIPL"), out, sep=",")
writeLines(paste("ADITOTAL"), out, sep=",")
writeLines(paste("PDRPLAN"), out, sep=",")
writeLines(paste("PDRREQ"), out, sep=",")
writeLines(paste("PDRSTP"), out, sep=",")
writeLines(paste("PDRREQINSP"), out, sep=",")
writeLines(paste("PDRHLD"), out, sep=",")
writeLines(paste("PDRITP"), out, sep=",")
writeLines(paste("PDRHLDINSP"), out, sep=",")
writeLines(paste("PDRDLD"), out, sep=",")
writeLines(paste("PDRDLDR"), out, sep=",")
writeLines(paste("PDRTD"), out, sep=",")
writeLines(paste("PDRDLDINSP"), out, sep=",")
writeLines(paste("PDRCODE"), out, sep=",")
writeLines(paste("PDRCR"), out, sep=",")
writeLines(paste("PDRCOMPILE"), out, sep=",")
writeLines(paste("PDRINSP"), out, sep=",")
writeLines(paste("PDRUT"), out, sep=",")
writeLines(paste("PDRBIT"), out, sep=",")
writeLines(paste("PDRST"), out, sep=",")
writeLines(paste("PDRAT"), out, sep=",")
writeLines(paste("PDRPL"), out, sep=",")
writeLines(paste("PDRTOTAL"), out, sep=",")
writeLines(paste("ADRPLAN"), out, sep=",")
writeLines(paste("ADRREQ"), out, sep=",")
writeLines(paste("ADRSTP"), out, sep=",")
writeLines(paste("ADRREQINSP"), out, sep=",")
writeLines(paste("ADRHLD"), out, sep=",")
writeLines(paste("ADRITP"), out, sep=",")
writeLines(paste("ADRHLDINSP"), out, sep=",")
writeLines(paste("ADRDLD"), out, sep=",")
writeLines(paste("ADRDLDR"), out, sep=",")
writeLines(paste("ADRTD"), out, sep=",")
writeLines(paste("ADRDLDINSP"), out, sep=",")
writeLines(paste("ADRCODE"), out, sep=",")
writeLines(paste("ADRCR"), out, sep=",")
writeLines(paste("ADRCOMPILE"), out, sep=",")
writeLines(paste("ADRINSP"), out, sep=",")
writeLines(paste("ADRUT"), out, sep=",")
writeLines(paste("ADRBIT"), out, sep=",")
writeLines(paste("ADRST"), out, sep=",")
writeLines(paste("ADRAT"), out, sep=",")
writeLines(paste("ADRPL"), out, sep=",")
writeLines(paste("ADRTOTAL"), out, sep=",")
writeLines(paste("PTMM"), out, sep=",")
writeLines(paste("PTLS"), out, sep=",")
writeLines(paste("PTPLAN"), out, sep=",")
writeLines(paste("PTREQ"), out, sep=",")
writeLines(paste("PTSTP"), out, sep=",")
writeLines(paste("PTREQINSP"), out, sep=",")
writeLines(paste("PTHLD"), out, sep=",")
writeLines(paste("PTITP"), out, sep=",")
writeLines(paste("PTHLDINSP"), out, sep=",")
writeLines(paste("PTDLD"), out, sep=",")
writeLines(paste("PTDLDR"), out, sep=",")
writeLines(paste("PTTD"), out, sep=",")
writeLines(paste("PTDLDINSP"), out, sep=",")
writeLines(paste("PTCODE"), out, sep=",")
writeLines(paste("PTCR"), out, sep=",")
writeLines(paste("PTCOMPILE"), out, sep=",")
writeLines(paste("PTINSP"), out, sep=",")
writeLines(paste("PTUT"), out, sep=",")
writeLines(paste("PTBIT"), out, sep=",")
writeLines(paste("PTST"), out, sep=",")
writeLines(paste("PTDOC"), out, sep=",")
writeLines(paste("PTPM"), out, sep=",")
writeLines(paste("PTAT"), out, sep=",")
writeLines(paste("PTPL"), out, sep=",")
writeLines(paste("PTTOTAL"), out, sep=",")
writeLines(paste("ATMM"), out, sep=",")
writeLines(paste("ATLS"), out, sep=",")
writeLines(paste("ATPLAN"), out, sep=",")
writeLines(paste("ATREQ"), out, sep=",")
writeLines(paste("ATSTP"), out, sep=",")
writeLines(paste("ATREQINSP"), out, sep=",")
writeLines(paste("ATHLD"), out, sep=",")
writeLines(paste("ATITP"), out, sep=",")
writeLines(paste("ATHLDINSP"), out, sep=",")
writeLines(paste("ATDLD"), out, sep=",")
writeLines(paste("ATDLDR"), out, sep=",")
writeLines(paste("ATTD"), out, sep=",")
writeLines(paste("ATDLDINSP"), out, sep=",")
writeLines(paste("ATCODE"), out, sep=",")
writeLines(paste("ATCR"), out, sep=",")
writeLines(paste("ATCOMPILE"), out, sep=",")
writeLines(paste("ATINSP"), out, sep=",")
writeLines(paste("ATUT"), out, sep=",")
writeLines(paste("ATBIT"), out, sep=",")
writeLines(paste("ATST"), out, sep=",")
writeLines(paste("ATDOC"), out, sep=",")
writeLines(paste("ATPM"), out, sep=",")
writeLines(paste("ATAT"), out, sep=",")
writeLines(paste("ATPL"), out, sep=",")
writeLines(paste("ATTOTAL"), out, sep=",")
writeLines(paste("PRATE_MM"), out, sep=",")
writeLines(paste("PRATE_LS"), out, sep=",")
writeLines(paste("PRATE_PLAN"), out, sep=",")
writeLines(paste("PRATE_REQ"), out, sep=",")
writeLines(paste("PRATE_STP"), out, sep=",")
writeLines(paste("PRATE_REQINSP"), out, sep=",")
writeLines(paste("PRATE_HLD"), out, sep=",")
writeLines(paste("PRATE_ITP"), out, sep=",")
writeLines(paste("PRATE_HLDINSP"), out, sep=",")
writeLines(paste("PRATE_DLD"), out, sep=",")
writeLines(paste("PRATE_DLDR"), out, sep=",")
writeLines(paste("PRATE_TD"), out, sep=",")
writeLines(paste("PRATE_DLDINSP"), out, sep=",")
writeLines(paste("PRATE_CODE"), out, sep=",")
writeLines(paste("PRATE_CR"), out, sep=",")
writeLines(paste("PRATE_COMPILE"), out, sep=",")
writeLines(paste("PRATE_INSP"), out, sep=",")
writeLines(paste("PRATE_UT"), out, sep=",")
writeLines(paste("PRATE_BIT"), out, sep=",")
writeLines(paste("PRATE_ST"), out, sep=",")
writeLines(paste("PRATE_DOC"), out, sep=",")
writeLines(paste("PRATE_PM"), out, sep=",")
writeLines(paste("PRATE_AT"), out, sep=",")
writeLines(paste("PRATE_PL"), out, sep=",")
writeLines(paste("ARATE_MM"), out, sep=",")
writeLines(paste("ARATE_LS"), out, sep=",")
writeLines(paste("ARATE_PLAN"), out, sep=",")
writeLines(paste("ARATE_REQ"), out, sep=",")
writeLines(paste("ARATE_STP"), out, sep=",")
writeLines(paste("ARATE_REQINSP"), out, sep=",")
writeLines(paste("ARATE_HLD"), out, sep=",")
writeLines(paste("ARATE_ITP"), out, sep=",")
writeLines(paste("ARATE_HLDINSP"), out, sep=",")
writeLines(paste("ARATE_DLD"), out, sep=",")
writeLines(paste("ARATE_DLDR"), out, sep=",")
writeLines(paste("ARATE_TD"), out, sep=",")
writeLines(paste("ARATE_DLDINSP"), out, sep=",")
writeLines(paste("ARATE_CODE"), out, sep=",")
writeLines(paste("ARATE_CR"), out, sep=",")
writeLines(paste("ARATE_COMPILE"), out, sep=",")
writeLines(paste("ARATE_INSP"), out, sep=",")
writeLines(paste("ARATE_UT"), out, sep=",")
writeLines(paste("ARATE_BIT"), out, sep=",")
writeLines(paste("ARATE_ST"), out, sep=",")
writeLines(paste("ARATE_DOC"), out, sep=",")
writeLines(paste("ARATE_PM"), out, sep=",")
writeLines(paste("ARATE_AT"), out, sep=",")
writeLines(paste("ARATE_PL"), out, sep=",")
writeLines(paste("PT_PERCENT_MM"), out, sep=",")
writeLines(paste("PT_PERCENT_LS"), out, sep=",")
writeLines(paste("PT_PERCENT_PLAN"), out, sep=",")
writeLines(paste("PT_PERCENT_REQ"), out, sep=",")
writeLines(paste("PT_PERCENT_STP"), out, sep=",")
writeLines(paste("PT_PERCENT_REQINSP"), out, sep=",")
writeLines(paste("PT_PERCENT_HLD"), out, sep=",")
writeLines(paste("PT_PERCENT_ITP"), out, sep=",")
writeLines(paste("PT_PERCENT_HLDINSP"), out, sep=",")
writeLines(paste("PT_PERCENT_DLD"), out, sep=",")
writeLines(paste("PT_PERCENT_DLDR"), out, sep=",")
writeLines(paste("PT_PERCENT_TD"), out, sep=",")
writeLines(paste("PT_PERCENT_DLDINSP"), out, sep=",")
writeLines(paste("PT_PERCENT_CODE"), out, sep=",")
writeLines(paste("PT_PERCENT_CR"), out, sep=",")
writeLines(paste("PT_PERCENT_COMPILE"), out, sep=",")
writeLines(paste("PT_PERCENT_INSP"), out, sep=",")
writeLines(paste("PT_PERCENT_UT"), out, sep=",")
writeLines(paste("PT_PERCENT_BIT"), out, sep=",")
writeLines(paste("PT_PERCENT_ST"), out, sep=",")
writeLines(paste("PT_PERCENT_DOC"), out, sep=",")
writeLines(paste("PT_PERCENT_PM"), out, sep=",")
writeLines(paste("PT_PERCENT_AT"), out, sep=",")
writeLines(paste("PT_PERCENT_PL"), out, sep=",")
writeLines(paste("AT_PERCENT_MM"), out, sep=",")
writeLines(paste("AT_PERCENT_LS"), out, sep=",")
writeLines(paste("AT_PERCENT_PLAN"), out, sep=",")
writeLines(paste("AT_PERCENT_REQ"), out, sep=",")
writeLines(paste("AT_PERCENT_STP"), out, sep=",")
writeLines(paste("AT_PERCENT_REQINSP"), out, sep=",")
writeLines(paste("AT_PERCENT_HLD"), out, sep=",")
writeLines(paste("AT_PERCENT_ITP"), out, sep=",")
writeLines(paste("AT_PERCENT_HLDINSP"), out, sep=",")
writeLines(paste("AT_PERCENT_DLD"), out, sep=",")
writeLines(paste("AT_PERCENT_DLDR"), out, sep=",")
writeLines(paste("AT_PERCENT_TD"), out, sep=",")
writeLines(paste("AT_PERCENT_DLDINSP"), out, sep=",")
writeLines(paste("AT_PERCENT_CODE"), out, sep=",")
writeLines(paste("AT_PERCENT_CR"), out, sep=",")
writeLines(paste("AT_PERCENT_COMPILE"), out, sep=",")
writeLines(paste("AT_PERCENT_INSP"), out, sep=",")
writeLines(paste("AT_PERCENT_UT"), out, sep=",")
writeLines(paste("AT_PERCENT_BIT"), out, sep=",")
writeLines(paste("AT_PERCENT_ST"), out, sep=",")
writeLines(paste("AT_PERCENT_DOC"), out, sep=",")
writeLines(paste("AT_PERCENT_PM"), out, sep=",")
writeLines(paste("AT_PERCENT_AT"), out, sep=",")
writeLines(paste("AT_PERCENT_PL"), out, sep=",")
writeLines(paste("PDINJ_RATE_PLAN"), out, sep=",")
writeLines(paste("PDINJ_RATE_REQ"), out, sep=",")
writeLines(paste("PDINJ_RATE_STP"), out, sep=",")
writeLines(paste("PDINJ_RATE_REQINSP"), out, sep=",")
writeLines(paste("PDINJ_RATE_HLD"), out, sep=",")
writeLines(paste("PDINJ_RATE_ITP"), out, sep=",")
writeLines(paste("PDINJ_RATE_HLDINSP"), out, sep=",")
writeLines(paste("PDINJ_RATE_DLD"), out, sep=",")
writeLines(paste("PDINJ_RATE_DLDR"), out, sep=",")
writeLines(paste("PDINJ_RATE_TD"), out, sep=",")
writeLines(paste("PDINJ_RATE_DLDINSP"), out, sep=",")
writeLines(paste("PDINJ_RATE_CODE"), out, sep=",")
writeLines(paste("PDINJ_RATE_CR"), out, sep=",")
writeLines(paste("PDINJ_RATE_COMPILE"), out, sep=",")
writeLines(paste("PDINJ_RATE_INSP"), out, sep=",")
writeLines(paste("PDINJ_RATE_UT"), out, sep=",")
writeLines(paste("PDINJ_RATE_BIT"), out, sep=",")
writeLines(paste("PDINJ_RATE_ST"), out, sep=",")
writeLines(paste("PDINJ_RATE_AT"), out, sep=",")
writeLines(paste("PDINJ_RATE_PL"), out, sep=",")
writeLines(paste("PDINJ_RATE_TOTAL"), out, sep=",")
writeLines(paste("ADINJ_RATE_PLAN"), out, sep=",")
writeLines(paste("ADINJ_RATE_REQ"), out, sep=",")
writeLines(paste("ADINJ_RATE_STP"), out, sep=",")
writeLines(paste("ADINJ_RATE_REQINSP"), out, sep=",")
writeLines(paste("ADINJ_RATE_HLD"), out, sep=",")
writeLines(paste("ADINJ_RATE_ITP"), out, sep=",")
writeLines(paste("ADINJ_RATE_HLDINSP"), out, sep=",")
writeLines(paste("ADINJ_RATE_DLD"), out, sep=",")
writeLines(paste("ADINJ_RATE_DLDR"), out, sep=",")
writeLines(paste("ADINJ_RATE_TD"), out, sep=",")
writeLines(paste("ADINJ_RATE_DLDINSP"), out, sep=",")
writeLines(paste("ADINJ_RATE_CODE"), out, sep=",")
writeLines(paste("ADINJ_RATE_CR"), out, sep=",")
writeLines(paste("ADINJ_RATE_COMPILE"), out, sep=",")
writeLines(paste("ADINJ_RATE_INSP"), out, sep=",")
writeLines(paste("ADINJ_RATE_UT"), out, sep=",")
writeLines(paste("ADINJ_RATE_BIT"), out, sep=",")
writeLines(paste("ADINJ_RATE_ST"), out, sep=",")
writeLines(paste("ADINJ_RATE_AT"), out, sep=",")
writeLines(paste("ADINJ_RATE_PL"), out, sep=",")
writeLines(paste("ADINJ_RATE_TOTAL"), out, sep=",")
writeLines(paste("PDREM_RATE_PLAN"), out, sep=",")
writeLines(paste("PDREM_RATE_REQ"), out, sep=",")
writeLines(paste("PDREM_RATE_STP"), out, sep=",")
writeLines(paste("PDREM_RATE_REQINSP"), out, sep=",")
writeLines(paste("PDREM_RATE_HLD"), out, sep=",")
writeLines(paste("PDREM_RATE_ITP"), out, sep=",")
writeLines(paste("PDREM_RATE_HLDINSP"), out, sep=",")
writeLines(paste("PDREM_RATE_DLD"), out, sep=",")
writeLines(paste("PDREM_RATE_DLDR"), out, sep=",")
writeLines(paste("PDREM_RATE_TD"), out, sep=",")
writeLines(paste("PDREM_RATE_DLDINSP"), out, sep=",")
writeLines(paste("PDREM_RATE_CODE"), out, sep=",")
writeLines(paste("PDREM_RATE_CR"), out, sep=",")
writeLines(paste("PDREM_RATE_COMPILE"), out, sep=",")
writeLines(paste("PDREM_RATE_INSP"), out, sep=",")
writeLines(paste("PDREM_RATE_UT"), out, sep=",")
writeLines(paste("PDREM_RATE_BIT"), out, sep=",")
writeLines(paste("PDREM_RATE_ST"), out, sep=",")
writeLines(paste("PDREM_RATE_AT"), out, sep=",")
writeLines(paste("PDREM_RATE_PL"), out, sep=",")
writeLines(paste("PDREM_RATE_TOTAL"), out, sep=",")
writeLines(paste("ADREM_RATE_PLAN"), out, sep=",")
writeLines(paste("ADREM_RATE_REQ"), out, sep=",")
writeLines(paste("ADREM_RATE_STP"), out, sep=",")
writeLines(paste("ADREM_RATE_REQINSP"), out, sep=",")
writeLines(paste("ADREM_RATE_HLD"), out, sep=",")
writeLines(paste("ADREM_RATE_ITP"), out, sep=",")
writeLines(paste("ADREM_RATE_HLDINSP"), out, sep=",")
writeLines(paste("ADREM_RATE_DLD"), out, sep=",")
writeLines(paste("ADREM_RATE_DLDR"), out, sep=",")
writeLines(paste("ADREM_RATE_TD"), out, sep=",")
writeLines(paste("ADREM_RATE_DLDINSP"), out, sep=",")
writeLines(paste("ADREM_RATE_CODE"), out, sep=",")
writeLines(paste("ADREM_RATE_CR"), out, sep=",")
writeLines(paste("ADREM_RATE_COMPILE"), out, sep=",")
writeLines(paste("ADREM_RATE_INSP"), out, sep=",")
writeLines(paste("ADREM_RATE_UT"), out, sep=",")
writeLines(paste("ADREM_RATE_BIT"), out, sep=",")
writeLines(paste("ADREM_RATE_ST"), out, sep=",")
writeLines(paste("ADREM_RATE_AT"), out, sep=",")
writeLines(paste("ADREM_RATE_PL"), out, sep=",")
writeLines(paste("ADREM_RATE_TOTAL"), out, sep=",")
writeLines(paste("PDREM_YIELD_PLAN"), out, sep=",")
writeLines(paste("PDREM_YIELD_REQ"), out, sep=",")
writeLines(paste("PDREM_YIELD_STP"), out, sep=",")
writeLines(paste("PDREM_YIELD_REQINSP"), out, sep=",")
writeLines(paste("PDREM_YIELD_HLD"), out, sep=",")
writeLines(paste("PDREM_YIELD_ITP"), out, sep=",")
writeLines(paste("PDREM_YIELD_HLDINSP"), out, sep=",")
writeLines(paste("PDREM_YIELD_DLD"), out, sep=",")
writeLines(paste("PDREM_YIELD_DLDR"), out, sep=",")
writeLines(paste("PDREM_YIELD_TD"), out, sep=",")
writeLines(paste("PDREM_YIELD_DLDINSP"), out, sep=",")
writeLines(paste("PDREM_YIELD_CODE"), out, sep=",")
writeLines(paste("PDREM_YIELD_CR"), out, sep=",")
writeLines(paste("PDREM_YIELD_COMPILE"), out, sep=",")
writeLines(paste("PDREM_YIELD_INSP"), out, sep=",")
writeLines(paste("PDREM_YIELD_UT"), out, sep=",")
writeLines(paste("PDREM_YIELD_BIT"), out, sep=",")
writeLines(paste("PDREM_YIELD_ST"), out, sep=",")
writeLines(paste("PDREM_YIELD_AT"), out, sep=",")
writeLines(paste("PDREM_YIELD_PL"), out, sep=",")
writeLines(paste("ADREM_YIELD_PLAN"), out, sep=",")
writeLines(paste("ADREM_YIELD_REQ"), out, sep=",")
writeLines(paste("ADREM_YIELD_STP"), out, sep=",")
writeLines(paste("ADREM_YIELD_REQINSP"), out, sep=",")
writeLines(paste("ADREM_YIELD_HLD"), out, sep=",")
writeLines(paste("ADREM_YIELD_ITP"), out, sep=",")
writeLines(paste("ADREM_YIELD_HLDINSP"), out, sep=",")
writeLines(paste("ADREM_YIELD_DLD"), out, sep=",")
writeLines(paste("ADREM_YIELD_DLDR"), out, sep=",")
writeLines(paste("ADREM_YIELD_TD"), out, sep=",")
writeLines(paste("ADREM_YIELD_DLDINSP"), out, sep=",")
writeLines(paste("ADREM_YIELD_CODE"), out, sep=",")
writeLines(paste("ADREM_YIELD_CR"), out, sep=",")
writeLines(paste("ADREM_YIELD_COMPILE"), out, sep=",")
writeLines(paste("ADREM_YIELD_INSP"), out, sep=",")
writeLines(paste("ADREM_YIELD_UT"), out, sep=",")
writeLines(paste("ADREM_YIELD_BIT"), out, sep=",")
writeLines(paste("ADREM_YIELD_ST"), out, sep=",")
writeLines(paste("ADREM_YIELD_AT"), out, sep=",")
writeLines(paste("ADREM_YIELD_PL"), out, sep=",")
writeLines(paste("PREMRATE_DEFECT_RATE_UT"), out, sep=",")
writeLines(paste("PREMRATE_DEFECT_RATE_BIT"), out, sep=",")
writeLines(paste("PREMRATE_DEFECT_RATE_ST"), out, sep=",")
writeLines(paste("PREMRATE_DEFECT_RATE_AT"), out, sep=",")
writeLines(paste("PREMRATE_DEFECT_RATE_PL"), out, sep=",")
writeLines(paste("PZero_DEFECT_RATE_UT"), out, sep=",")
writeLines(paste("PZero_DEFECT_RATE_BIT"), out, sep=",")
writeLines(paste("PZero_DEFECT_RATE_ST"), out, sep=",")
writeLines(paste("PZero_DEFECT_RATE_AT"), out, sep=",")
writeLines(paste("PZero_DEFECT_RATE_PL"), out, sep=",")
writeLines(paste("AM Size Estimation Accuracy"), out, sep=",")
writeLines(paste("Effort Estimation Accuracy"), out, sep=",")
writeLines(paste("Actual Production Rate"), out, sep=",")
writeLines(paste("TRREQINSP2REQ"), out, sep=",")
writeLines(paste("TRHLDINSP2HLD"), out, sep=",")
writeLines(paste("TRDLDINSP2DLD"), out, sep=",")
writeLines(paste("TRDLDR2DLD"), out, sep=",")
writeLines(paste("TRCODEINSP2CODE"), out, sep=",")
writeLines(paste("TRCR2CODE"), out, sep=",")
writeLines(paste("TRDESGN2CODE"), out, sep=",")
writeLines(paste("COQPct"), out, sep=",")
writeLines(paste("COQPct Appraisal"), out, sep=",")
writeLines(paste("COQPct Failure"), out, sep=",")
writeLines(paste("Defect Density DLDR"), out, sep=",")
writeLines(paste("Defect Density DLDINSP"), out, sep=",")
writeLines(paste("Defect Density CR"), out, sep=",")
writeLines(paste("Defect Density Compile"), out, sep=",")
writeLines(paste("Defect Density INSP"), out, sep=",")
writeLines(paste("Defect Density UT"), out, sep=",")
writeLines(paste("Defect Density BIT"), out, sep=",")
writeLines(paste("Defect Density ST"), out, sep=",")
writeLines(paste("Defect Density Total"), out, sep=",")
writeLines(paste("COAratio_size"), out, sep=",")
writeLines(paste("COFratio_size"), out, sep=",")
writeLines(paste("COQratio_size"), out, sep=",")
writeLines(paste("construction effort"), out, sep=",")
writeLines(paste("total effort"), out, sep=",")
writeLines(paste("Production Rate (const effort)"), out, sep=",")
writeLines(paste("Production Rate (total effort)"), out, sep=",")
writeLines(paste("COAinDLDUT"), out, sep=",")
writeLines(paste("COFinDLDUT"), out, sep=",")
writeLines(paste("COQinDLDUT"), out, sep=",")
writeLines(paste("COAinDLDUTratio_size"), out, sep=",")
writeLines(paste("COFinDLDUTratio_size"), out, sep=",")
writeLines(paste("COQinDLDUTratio_size"), out, sep=",")
writeLines(paste("DEFFIXTUT"), out, sep="\n")

## Extract data by each project
for (element in component_elements) {
  
  ## Extract task effort data from task status fact hist table    
  time_info <- subset(tab_time_info, wbs_element_key==element)
  
  # Go to next iteration, if wbs_element_key do not have any phase
  if (length(time_info$phase_short_name) == 0) {
    next
  }
  
  ## Prepare vecto for internal variable
  phase_vector <- list()
  
  ## Extrac component inormation from WBS element table
  component_info <- subset(tab_component_info, wbs_element_key==element) 
  org_name <- NoData
  wbs_element_name <- unique(component_info$wbs_element_name)
  project_key <- paste(component_info$project_key, collapse=";")
  
  ## Extract team and individuals information
  team_info <- subset(tab_teams_info, wbs_element_key==element)
  
  if (length(unique(team_info$team_key)) == 0) {
    team_key <- NoData
  } else {
    team_key_tmp <- unique(team_info$team_key)
    team_key <- paste(team_key_tmp, collapse=";")
  }
    
  if (length(team_info$person_key) == 0) {
    team_size <- NoData
    individuals <- NoData
  } else {
    team_size <- length(team_info$person_key)
    individuals <- paste(team_info$person_key, collapse=";")
  }
  
  ## Extract process information
  process_info <- subset(tab_process_info, wbs_element_key==element)
  
  if (length(process_info$process_name) == 0) {
    process_name <- NoData
  } else {
    process_name <- process_info$process_name
  }
  
  ## Extract component date informatio from time log fact hist table
  component_duration_info <- subset(tab_component_duration, wbs_element_key==element)
  
  if (length(component_duration_info$start_date) == 0) {
    start_date_char <- NoData
  } else {
    start_date_char <- component_duration_info$start_date
  }
  
  if (length(component_duration_info$end_date) == 0) {
    end_date_char <- NoData
  } else {
    end_date_char <- component_duration_info$end_date
  }
  
  ## Extract earned value from ev schedule period fact hist table
  ev_info <- subset(tab_ev_info, wbs_element_key==element)
  ev_complete_info <- subset(ev_info, task_actual_complete_date_key < 99990000)
  bcws_info <- subset(tab_bcws_info, wbs_element_key==element)
  
  BAC <- sum(ev_info$task_plan_time_minutes, na.rm=TRUE)/60
  BCWP <- sum(ev_complete_info$task_plan_time_minutes, na.rm=TRUE)/60
  ACWP <- sum(ev_complete_info$task_actual_time_minutes, na.rm=TRUE)/60
  
  if (length(bcws_info$sum_plan_minutes) == 0) {
    BCWS <- 0
  } else {
    BCWS <- bcws_info$sum_plan_minutes/60
  }
  
  CPI <- BCWP/ACWP
  SPI <- BCWP/BCWS
  CV <- BCWP-ACWP
  SV <- BCWP-BCWS
  CumPV <- BAC
  CumEV <- BCWP
  Final_EV <- NoData
  
  ## task hours estimation
  baseline_task_hours <- NoData
  component_comp_parts_plan_hours <- BCWP
  component_comp_parts_actual_hours <- ACWP
  growth_task_hours_baseline <- NoData
  task_estimation_accuracy <- NoData
  
  plan_date_set <- subset(ev_info, task_date_key < 99999000)

  if (length(plan_date_set$task_date_key) == 0) {
    plan_date <- NoData
  } else {
    plan_date <- max(plan_date_set$task_date_key)
  }
  
  baseline_date <- NoData
  predicted_date <- NoData
  start_week <- NoData
  actual_week <- NoData
  plan_weeks <- NoData
  baseline_weeks <- NoData
  growth_schedule_baseline <- NoData
  
  ## Calculate component duration
  if (length(component_duration_info$start_date) == 0 || length(component_duration_info$end_date) == 0) {
    component_networkdays <- 0
  } else {
    start_date_char_vector <- unlist(strsplit(start_date_char, "-"))
    end_date_char_vector <- unlist(strsplit(end_date_char, "-"))
    
    start_date_year <- as.numeric(start_date_char_vector[1])
    start_date_month <- as.numeric(start_date_char_vector[2])
    start_day_vector <- unlist(strsplit(start_date_char_vector[3], " "))
    start_date_day <- as.numeric(start_day_vector[1])
    
    end_date_year <- as.numeric(end_date_char_vector[1])
    end_date_month <- as.numeric(end_date_char_vector[2])
    end_day_vector <- unlist(strsplit(end_date_char_vector[3], " "))
    end_date_day <- as.numeric(end_day_vector[1])
    
    if ((start_date_year >= 2000) && (end_date_year >= 2000)) {
      if ((start_date_month <= 12) && (end_date_month <= 12)) {
        if ((start_date_day <= 31) && (end_date_day <= 31)) {
  	      component_start_date <- as.Date(start_date_char)
  	      component_end_date <- as.Date(end_date_char)
            
  	      component_networkdays <- networkdays(component_start_date, component_end_date)
        }
      }
    }
  }
  
  ## Calculate plan task hours and actual task hours by using time_info
  actual_task_hours <- sum(time_info$sum_actual_time, na.rm=TRUE)/60
  plan_task_hours <- sum(time_info$sum_plan_time, na.rm=TRUE)/60
  mean_team_hours_week <- NoData
  mean_team_member_hours_week <- NoData
  
  ## Benford
  time_benford_mad <- NoData
  defect_benford_mad <- NoData
  
  ## Extract plan size and actual size infomation from size fact hist table 
  plan_size_info <- subset(tab_size_info, wbs_element_key==element & measurement_type_key=="1" & size_metric_name=="Lines of Code")
  actual_size_info <- subset(tab_size_info, wbs_element_key==element & measurement_type_key=="4" & size_metric_name=="Lines of Code")
  
  if (length(plan_size_info$sum_size_base) == 0 || is.na(plan_size_info$sum_size_base)) {
    planB <- 0
  } else {
    planB <- plan_size_info$sum_size_base
  }

  if (length(plan_size_info$sum_size_deleted) == 0 || is.na(plan_size_info$sum_size_deleted)) {
    planD <- 0
  } else {
    planD <- plan_size_info$sum_size_deleted
  }
  
  if (length(plan_size_info$sum_size_modified) == 0 || is.na(plan_size_info$sum_size_modified)) {
    planM <- 0
  } else {
    planM <- plan_size_info$sum_size_modified
  }
  
  if (length(plan_size_info$sum_size_added) == 0 || is.na(plan_size_info$sum_size_added)) {
    planA <- 0
  } else {
    planA <- plan_size_info$sum_size_added
  }
  
  if (length(plan_size_info$sum_size_reused) == 0 || is.na(plan_size_info$sum_size_reused)) {
    planR <- 0
  } else {
    planR <- plan_size_info$sum_size_reused
  }
  
  if (length(plan_size_info$sum_size_am) == 0 || is.na(plan_size_info$sum_size_am)) {
    planAM <- 0
  } else {
    planAM <- plan_size_info$sum_size_am
  }
  
  if (length(plan_size_info$sum_size_total) == 0 || is.na(plan_size_info$sum_size_total)) {
    planT <- 0
  } else {
    planT <- plan_size_info$sum_size_total
  }
  
  planNR <- NoData
  
  if (length(actual_size_info$sum_size_base) == 0 || is.na(actual_size_info$sum_size_base)) {
    actualB <- 0
  } else {
    actualB <- actual_size_info$sum_size_base
  }
  
  if (length(actual_size_info$sum_size_deleted) == 0 || is.na(actual_size_info$sum_size_deleted)) {
    actualD <- 0
  } else {
    actualD <- actual_size_info$sum_size_deleted
  }
  
  if (length(actual_size_info$sum_size_modified) == 0 || is.na(actual_size_info$sum_size_modified)) {
    actualM <- 0
  } else {
    actualM <- actual_size_info$sum_size_modified
  }
  
  if (length(actual_size_info$sum_size_added) == 0 || is.na(actual_size_info$sum_size_added)) {
    actualA <- 0
  } else {
    actualA <- actual_size_info$sum_size_added
  }
  
  if (length(actual_size_info$sum_size_reused) == 0 || is.na(actual_size_info$sum_size_reused)) {
    actualR <- 0
  } else {
    actualR <- actual_size_info$sum_size_reused
  }
  
  if (length(actual_size_info$sum_size_am) == 0 || is.na(actual_size_info$sum_size_am)) {
    actualAM <- 0
  } else {
    actualAM <- actual_size_info$sum_size_am
  }
  
  if (length(actual_size_info$sum_size_total) == 0 || is.na(actual_size_info$sum_size_total)) {
    actualT <- 0
  } else {
    actualT <- actual_size_info$sum_size_total
  }
  
  actualNR <- NoData

  ## Extract defect injected and defect removed information from defect log fact hist table  
  # Extract defect injected and defect removed information by each project
  defect_inj_info <- subset(tab_defect_injected_info, wbs_element_key==element)
  defect_rem_info <- subset(tab_defect_removed_info, wbs_element_key==element)
  
  # Extract defect injected information by each phase
  adiplan_set <- subset(defect_inj_info, defect_injected_phase_name=="Planning")
  adireq_set <- subset(defect_inj_info, defect_injected_phase_name=="Reqts")
  adistp_set <- subset(defect_inj_info, defect_injected_phase_name=="Sys Test Plan")
  adireqr_set <- subset(defect_inj_info, defect_injected_phase_name=="Reqts Review")
  adireqinsp_set <- subset(defect_inj_info, defect_injected_phase_name=="Reqts Inspect")
  adihld_set <- subset(defect_inj_info, defect_injected_phase_name=="HLD")
  adiitp_set <- subset(defect_inj_info, defect_injected_phase_name=="Int Test Plan")
  adihldr_set <- subset(defect_inj_info, defect_injected_phase_name=="HLD Review")
  adihldinsp_set <- subset(defect_inj_info, defect_injected_phase_name=="HLD Inspect")
  adidld_set <- subset(defect_inj_info, defect_injected_phase_name=="Design")
  adidldr_set <- subset(defect_inj_info, defect_injected_phase_name=="Design Review")
  aditd_set <- subset(defect_inj_info, defect_injected_phase_name=="Test Devel")
  adidldinsp_set <- subset(defect_inj_info, defect_injected_phase_name=="Design Inspect")
  adicode_set <- subset(defect_inj_info, defect_injected_phase_name=="Code")
  adicr_set <- subset(defect_inj_info, defect_injected_phase_name=="Code Review")
  adicompile_set <- subset(defect_inj_info, defect_injected_phase_name=="Compile")
  adiinsp_set <- subset(defect_inj_info, defect_injected_phase_name=="Code Inspect")
  adiut_set <- subset(defect_inj_info, defect_injected_phase_name=="Test")
  adibit_set <- subset(defect_inj_info, defect_injected_phase_name=="Int Test")
  adist_set <- subset(defect_inj_info, defect_injected_phase_name=="Sys Test")
  adiat_set <- subset(defect_inj_info, defect_injected_phase_name=="Accept Test")
  adipl_set <- subset(defect_inj_info, defect_injected_phase_name=="Product Life")
  
  # Extract defect removed information by each phase
  adrplan_set <- subset(defect_rem_info, defect_removed_phase_name=="Planning")
  adrreq_set <- subset(defect_rem_info, defect_removed_phase_name=="Reqts")
  adrstp_set <- subset(defect_rem_info, defect_removed_phase_name=="Sys Test Plan")
  adrreqr_set <- subset(defect_rem_info, defect_removed_phase_name=="Reqts Review")
  adrreqinsp_set <- subset(defect_rem_info, defect_removed_phase_name=="Reqts Inspect")
  adrhld_set <- subset(defect_rem_info, defect_removed_phase_name=="HLD")
  adritp_set <- subset(defect_rem_info, defect_removed_phase_name=="Int Test Plan")
  adrhldr_set <- subset(defect_rem_info, defect_removed_phase_name=="HLD Review")
  adrhldinsp_set <- subset(defect_rem_info, defect_removed_phase_name=="HLD Inspect")
  adrdld_set <- subset(defect_rem_info, defect_removed_phase_name=="Design")
  adrdldr_set <- subset(defect_rem_info, defect_removed_phase_name=="Design Review")
  adrtd_set <- subset(defect_rem_info, defect_removed_phase_name=="Test Devel")
  adrdldinsp_set <- subset(defect_rem_info, defect_removed_phase_name=="Design Inspect")
  adrcode_set <- subset(defect_rem_info, defect_removed_phase_name=="Code")
  adrcr_set <- subset(defect_rem_info, defect_removed_phase_name=="Code Review")
  adrcompile_set <- subset(defect_rem_info, defect_removed_phase_name=="Compile")
  adrinsp_set <- subset(defect_rem_info, defect_removed_phase_name=="Code Inspect")
  adrut_set <- subset(defect_rem_info, defect_removed_phase_name=="Test")
  adrbit_set <- subset(defect_rem_info, defect_removed_phase_name=="Int Test")
  adrst_set <- subset(defect_rem_info, defect_removed_phase_name=="Sys Test")
  adrat_set <- subset(defect_rem_info, defect_removed_phase_name=="Accept Test")
  adrpl_set <- subset(defect_rem_info, defect_removed_phase_name=="Product Life")
  
  # Extract Plan Defects Injected
  PDIPLAN <- NoData
  PDIREQ <- NoData
  PDISTP <- NoData
  PDIREQINSP <- NoData
  PDIHLD <- NoData
  PDIITP <- NoData
  PDIHLDINSP <- NoData
  PDIDLD <- NoData
  PDIDLDR <- NoData
  PDITD <- NoData
  PDIDLDINSP <- NoData
  PDICODE <- NoData
  PDICR <- NoData
  PDICOMPILE <- NoData
  PDIINSP <- NoData
  PDIUT <- NoData
  PDIBIT <- NoData
  PDIST <- NoData
  PDIAT <- NoData
  PDIPL <- NoData
  PDITOTAL <- NoData
  
  # Extract Actual Defect Injected
  if (length(adiplan_set$sum_defect_fix_count) == 0 || is.na(adiplan_set$sum_defect_fix_count)) {
    ADIPLAN <- 0
  } else {
    ADIPLAN <- adiplan_set$sum_defect_fix_count
  }
  
  if (length(adireq_set$sum_defect_fix_count) == 0 || is.na(adireq_set$sum_defect_fix_count)) {
    ADIREQ <- 0
  } else {
    ADIREQ <- adireq_set$sum_defect_fix_count
  }
  
  if (length(adistp_set$sum_defect_fix_count) == 0 || is.na(adistp_set$sum_defect_fix_count)) {
    ADISTP <- 0
  } else {
    ADISTP <- adistp_set$sum_defect_fix_count
  }

  if (length(adireqr_set$sum_defect_fix_count) == 0 || is.na(adireqr_set$sum_defect_fix_count)) {
    ADIREQR <- 0
  } else {
    ADIREQR <- adireqinsp_set$sum_defect_fix_count
  }
    
  if (length(adireqinsp_set$sum_defect_fix_count) == 0 || is.na(adireqinsp_set$sum_defect_fix_count)) {
    ADIREQINSP <- 0
  } else {
    ADIREQINSP <- adireqinsp_set$sum_defect_fix_count
  }
  
  if (length(adihld_set$sum_defect_fix_count) == 0 || is.na(adihld_set$sum_defect_fix_count)) {
    ADIHLD <- 0
  } else {
    ADIHLD <- adihld_set$sum_defect_fix_count
  }
  
  if (length(adiitp_set$sum_defect_fix_count) == 0 || is.na(adiitp_set$sum_defect_fix_count)) {
    ADIITP <- 0
  } else {
    ADIITP <- adiitp_set$sum_defect_fix_count
  }

  if (length(adihldr_set$sum_defect_fix_count) == 0 || is.na(adihldr_set$sum_defect_fix_count)) {
    ADIHLDR <- 0
  } else {
    ADIHLDR <- adihldinsp_set$sum_defect_fix_count
  }
    
  if (length(adihldinsp_set$sum_defect_fix_count) == 0 || is.na(adihldinsp_set$sum_defect_fix_count)) {
    ADIHLDINSP <- 0
  } else {
    ADIHLDINSP <- adihldinsp_set$sum_defect_fix_count
  }
  
  if (length(adidld_set$sum_defect_fix_count) == 0 || is.na(adidld_set$sum_defect_fix_count)) {
    ADIDLD <- 0
  } else {
    ADIDLD <- adidld_set$sum_defect_fix_count
  }
  
  if (length(adidldr_set$sum_defect_fix_count) == 0 || is.na(adidldr_set$sum_defect_fix_count)) {
    ADIDLDR <- 0
  } else {
    ADIDLDR <- adidldr_set$sum_defect_fix_count
  }

  if (length(aditd_set$sum_defect_fix_count) == 0 || is.na(aditd_set$sum_defect_fix_count)) {
    ADITD <- 0
  } else {
    ADITD <- aditd_set$sum_defect_fix_count
  }
    
  if (length(adidldinsp_set$sum_defect_fix_count) == 0 || is.na(adidldinsp_set$sum_defect_fix_count)) {
    ADIDLDINSP <- 0
  } else {
    ADIDLDINSP <- adidldinsp_set$sum_defect_fix_count
  }
  
  if (length(adicode_set$sum_defect_fix_count) == 0 || is.na(adicode_set$sum_defect_fix_count)) {
    ADICODE <- 0
  } else {
    ADICODE <- adicode_set$sum_defect_fix_count
  }
  
  if (length(adicr_set$sum_defect_fix_count) == 0 || is.na(adicr_set$sum_defect_fix_count)) {
    ADICR <- 0
  } else {
    ADICR <- adicr_set$sum_defect_fix_count
  }
  
  if (length(adicompile_set$sum_defect_fix_count) == 0 || is.na(adicompile_set$sum_defect_fix_count)) {
    ADICOMPILE <- 0
  } else {
    ADICOMPILE <- adicompile_set$sum_defect_fix_count
  }
  
  if (length(adiinsp_set$sum_defect_fix_count) == 0 || is.na(adiinsp_set$sum_defect_fix_count)) {
    ADIINSP <- 0
  } else {
    ADIINSP <- adiinsp_set$sum_defect_fix_count
  }
  
  if (length(adiut_set$sum_defect_fix_count) == 0 || is.na(adiut_set$sum_defect_fix_count)) {
    ADIUT <- 0
  } else {
    ADIUT <- adiut_set$sum_defect_fix_count
  }
  
  if (length(adibit_set$sum_defect_fix_count) == 0 || is.na(adibit_set$sum_defect_fix_count)) {
    ADIBIT <- 0
  } else {
    ADIBIT <- adibit_set$sum_defect_fix_count
  }
  
  if (length(adist_set$sum_defect_fix_count) == 0 || is.na(adist_set$sum_defect_fix_count)) {
    ADIST <- 0
  } else {
    ADIST <- adist_set$sum_defect_fix_count
  }
  
  if (length(adiat_set$sum_defect_fix_count) == 0 || is.na(adiat_set$sum_defect_fix_count)) {
    ADIAT <- 0
  } else {
    ADIAT <- adiat_set$sum_defect_fix_count
  }
  
  if (length(adipl_set$sum_defect_fix_count) == 0 || is.na(adipl_set$sum_defect_fix_count)) {
    ADIPL <- 0
  } else {
    ADIPL <- adipl_set$sum_defect_fix_count
  }
  
  ADITOTAL <- sum(defect_inj_info$sum_defect_fix_count, na.rm=TRUE)
  
  # Extract Plan Defects Removed
  PDRPLAN <- NoData
  PDRREQ <- NoData
  PDRSTP <- NoData
  PDRREQINSP <- NoData
  PDRHLD <- NoData
  PDRITP <- NoData
  PDRHLDINSP <- NoData
  PDRDLD <- NoData
  PDRDLDR <- NoData
  PDRTD <- NoData
  PDRDLDINSP <- NoData
  PDRCODE <- NoData
  PDRCR <- NoData
  PDRCOMPILE <- NoData
  PDRINSP <- NoData
  PDRUT <- NoData
  PDRBIT <- NoData
  PDRST <- NoData
  PDRAT <- NoData
  PDRPL <- NoData
  PDRTOTAL <- NoData
  
  # Extract Actual Defect Injected
  if (length(adrplan_set$sum_defect_fix_count) == 0 || is.na(adrplan_set$sum_defect_fix_count)) {
    ADRPLAN <- 0
  } else {
    ADRPLAN <- adrplan_set$sum_defect_fix_count
  }
  
  if (length(adrreq_set$sum_defect_fix_count) == 0 || is.na(adrreq_set$sum_defect_fix_count)) {
    ADRREQ <- 0
  } else {
    ADRREQ <- adrreq_set$sum_defect_fix_count
  }
  
  if (length(adrstp_set$sum_defect_fix_count) == 0 || is.na(adrstp_set$sum_defect_fix_count)) {
    ADRSTP <- 0
  } else {
    ADRSTP <- adrstp_set$sum_defect_fix_count
  }

  if (length(adrreqr_set$sum_defect_fix_count) == 0 || is.na(adrreqr_set$sum_defect_fix_count)) {
    ADRREQR <- 0
  } else {
    ADRREQR <- adrreqinsp_set$sum_defect_fix_count
  }
    
  if (length(adrreqinsp_set$sum_defect_fix_count) == 0 || is.na(adrreqinsp_set$sum_defect_fix_count)) {
    ADRREQINSP <- 0
  } else {
    ADRREQINSP <- adrreqinsp_set$sum_defect_fix_count
  }
  
  if (length(adrhld_set$sum_defect_fix_count) == 0 || is.na(adrhld_set$sum_defect_fix_count)) {
    ADRHLD <- 0
  } else {
    ADRHLD <- adrhld_set$sum_defect_fix_count
  }
  
  if (length(adritp_set$sum_defect_fix_count) == 0 || is.na(adritp_set$sum_defect_fix_count)) {
    ADRITP <- 0
  } else {
    ADRITP <- adritp_set$sum_defect_fix_count
  }

  if (length(adrhldr_set$sum_defect_fix_count) == 0 || is.na(adrhldr_set$sum_defect_fix_count)) {
    ADRHLDR <- 0
  } else {
    ADRHLDR <- adrhldinsp_set$sum_defect_fix_count
  }
    
  if (length(adrhldinsp_set$sum_defect_fix_count) == 0 || is.na(adrhldinsp_set$sum_defect_fix_count)) {
    ADRHLDINSP <- 0
  } else {
    ADRHLDINSP <- adrhldinsp_set$sum_defect_fix_count
  }
  
  if (length(adrdld_set$sum_defect_fix_count) == 0 || is.na(adrdld_set$sum_defect_fix_count)) {
    ADRDLD <- 0
  } else {
    ADRDLD <- adrdld_set$sum_defect_fix_count
  }
  
  if (length(adrdldr_set$sum_defect_fix_count) == 0 || is.na(adrdldr_set$sum_defect_fix_count)) {
    ADRDLDR <- 0
  } else {
    ADRDLDR <- adrdldr_set$sum_defect_fix_count
  }
  
  if (length(adrtd_set$sum_defect_fix_count) == 0 || is.na(adrtd_set$sum_defect_fix_count)) {
    ADRTD <- 0
  } else {
    ADRTD <- aditd_set$sum_defect_fix_count
  }
  
  if (length(adrdldinsp_set$sum_defect_fix_count) == 0 || is.na(adrdldinsp_set$sum_defect_fix_count)) {
    ADRDLDINSP <- 0
  } else {
    ADRDLDINSP <- adrdldinsp_set$sum_defect_fix_count
  }
  
  if (length(adrcode_set$sum_defect_fix_count) == 0 || is.na(adrcode_set$sum_defect_fix_count)) {
    ADRCODE <- 0
  } else {
    ADRCODE <- adrcode_set$sum_defect_fix_count
  }
  
  if (length(adrcr_set$sum_defect_fix_count) == 0 || is.na(adrcr_set$sum_defect_fix_count)) {
    ADRCR <- 0
  } else {
    ADRCR <- adrcr_set$sum_defect_fix_count
  }
  
  if (length(adrcompile_set$sum_defect_fix_count) == 0 || is.na(adrcompile_set$sum_defect_fix_count)) {
    ADRCOMPILE <- 0
  } else {
    ADRCOMPILE <- adrcompile_set$sum_defect_fix_count
  }
  
  if (length(adrinsp_set$sum_defect_fix_count) == 0 || is.na(adrinsp_set$sum_defect_fix_count)) {
    ADRINSP <- 0
  } else {
    ADRINSP <- adrinsp_set$sum_defect_fix_count
  }
  
  if (length(adrut_set$sum_defect_fix_count) == 0 || is.na(adrut_set$sum_defect_fix_count)) {
    ADRUT <- 0
  } else {
    ADRUT <- adrut_set$sum_defect_fix_count
  }
  
  if (length(adrbit_set$sum_defect_fix_count) == 0 || is.na(adrbit_set$sum_defect_fix_count)) {
    ADRBIT <- 0
  } else {
    ADRBIT <- adrbit_set$sum_defect_fix_count
  }
  
  if (length(adrst_set$sum_defect_fix_count) == 0 || is.na(adrst_set$sum_defect_fix_count)) {
    ADRST <- 0
  } else {
    ADRST <- adrst_set$sum_defect_fix_count
  }
  
  if (length(adrat_set$sum_defect_fix_count) == 0 || is.na(adrat_set$sum_defect_fix_count)) {
    ADRAT <- 0
  } else {
    ADRAT <- adrat_set$sum_defect_fix_count
  }
  
  if (length(adrpl_set$sum_defect_fix_count) == 0 || is.na(adrpl_set$sum_defect_fix_count)) {
    ADRPL <- 0
  } else {
    ADRPL <- adrpl_set$sum_defect_fix_count
  }
  
  ADRTOTAL <- sum(defect_rem_info$sum_defect_fix_count, na.rm=TRUE)
  
  # Extract defect find and fix time in each phase
  defect_fix_time_info <- subset(tab_defect_fix_time_info, wbs_element_key==element)
  deft_ut_set <- subset(defect_fix_time_info, phase_short_name=="Test")
  
  if (length(deft_ut_set$sum_defect_fix_time) == 0 || is.na(deft_ut_set$sum_defect_fix_time)) {
    DEFFIXTUT <- 0
  } else {
    DEFFIXTUT <- deft_ut_set$sum_defect_fix_time/60
  }
  
  # Extract time in phase information from task status fact hist table by each phase 
  tmm_set <- subset(time_info, phase_short_name=="Misc")
  tls_set <- subset(time_info, phase_short_name=="Strategy")
  tplan_set <- subset(time_info, phase_short_name=="Planning")
  treq_set <- subset(time_info, phase_short_name=="Reqts")
  tstp_set <- subset(time_info, phase_short_name=="Sys Test Plan")
  treqinsp_set <- subset(time_info, phase_short_name=="Reqts Inspect")
  thld_set <- subset(time_info, phase_short_name=="HLD")
  titp_set <- subset(time_info, phase_short_name=="Int Test Plan")
  thldinsp_set <- subset(time_info, phase_short_name=="HLD Inspect")
  tdld_set <- subset(time_info, phase_short_name=="Design")
  tdldr_set <- subset(time_info, phase_short_name=="Design Review")
  ttd_set <- subset(time_info, phase_short_name=="Test Devel")
  tdldinsp_set <- subset(time_info, phase_short_name=="Design Inspect")
  tcode_set <- subset(time_info, phase_short_name=="Code")
  tcr_set <- subset(time_info, phase_short_name=="Code Review")
  tcompile_set <- subset(time_info, phase_short_name=="Compile")
  tinsp_set <- subset(time_info, phase_short_name=="Code Inspect")
  tut_set <- subset(time_info, phase_short_name=="Test")
  tbit_set <- subset(time_info, phase_short_name=="Int Test")
  tst_set <- subset(time_info, phase_short_name=="Sys Test")
  tdoc_set <- subset(time_info, phase_short_name=="Documentation")
  tpm_set <- subset(time_info, phase_short_name=="Postmortem")
  tat_set <- subset(time_info, phase_short_name=="Accept Test")
  tpl_set <- subset(time_info, phase_short_name=="Product Life")
  total_plan_minutes <- sum(time_info$sum_plan_time, na.rm=TRUE)
  total_actual_minutes <- sum(time_info$sum_actual_time, na.rm=TRUE)
  
  # Extract Planned Time in Phase, Planned Phase Rate, and  Planned Time Percent in Phase
  if (length(tmm_set$sum_plan_time) == 0 || is.na(tmm_set$sum_plan_time)) {
    PTMM <- 0
    PRATE_MM <- 0
    PT_PERCENT_MM <- 0
  } else {
    PTMM <- tmm_set$sum_plan_time
    PRATE_MM <- planAM/PTMM*60
    PT_PERCENT_MM <- PTMM/total_plan_minutes*100
  }
  
  if (length(tls_set$sum_plan_time) == 0 || is.na(tls_set$sum_plan_time)) {
    PTLS <- 0
    PRATE_LS <- 0
    PT_PERCENT_LS <- 0
  } else {
    PTLS <- tls_set$sum_plan_time
    PRATE_LS <- planAM/PTLS*60
    PT_PERCENT_LS <- PTLS/total_plan_minutes*100
  }
  
  if (length(tplan_set$sum_plan_time) == 0 || is.na(tplan_set$sum_plan_time)) {
    PTPLAN <- 0
    PRATE_PLAN <- 0
    PT_PERCENT_PLAN <- 0
  } else {
    PTPLAN <- tplan_set$sum_plan_time
    PRATE_PLAN <- planAM/PTPLAN*60
    PT_PERCENT_PLAN <- PTPLAN/total_plan_minutes*100
  }
  
  if (length(treq_set$sum_plan_time) == 0 || is.na(treq_set$sum_plan_time)) {
    PTREQ <- 0
    PRATE_REQ <- 0
    PT_PERCENT_REQ <- 0
  } else {
    PTREQ <- treq_set$sum_plan_time
    PRATE_REQ <- planAM/PTREQ*60
    PT_PERCENT_REQ <- PTREQ/total_plan_minutes*100
  }
  
  if (length(tstp_set$sum_plan_time) == 0 || is.na(tstp_set$sum_plan_time)) {
    PTSTP <- 0
    PRATE_STP <- 0
    PT_PERCENT_STP <- 0
  } else {
    PTSTP <- tstp_set$sum_plan_time
    PRATE_STP <- planAM/PTSTP*60
    PT_PERCENT_STP <- PTSTP/total_plan_minutes*100
  }
  
  if (length(treqinsp_set$sum_plan_time) == 0 || is.na(treqinsp_set$sum_plan_time)) {
    PTREQINSP <- 0
    PRATE_REQINSP <- 0
    PT_PERCENT_REQINSP <- 0
  } else {
    PTREQINSP <- treqinsp_set$sum_plan_time
    PRATE_REQINSP <- planAM/PTREQINSP*60
    PT_PERCENT_REQINSP <- PTREQINSP/total_plan_minutes*100
  }
  
  if (length(thld_set$sum_plan_time) == 0 || is.na(thld_set$sum_plan_time)) {
    PTHLD <- 0
    PRATE_HLD <- 0
    PT_PERCENT_HLD <- 0
  } else {  
    PTHLD <- thld_set$sum_plan_time
    PRATE_HLD <- planAM/PTHLD*60
    PT_PERCENT_HLD <- PTHLD/total_plan_minutes*100
  }
  
  if (length(titp_set$sum_plan_time) == 0 || is.na(titp_set$sum_plan_time)) {
    PTITP <- 0
    PRATE_ITP <- 0
    PT_PERCENT_ITP <- 0
  } else {
    PTITP <- titp_set$sum_plan_time
    PRATE_ITP <- planAM/PTITP*60
    PT_PERCENT_ITP <- PTITP/total_plan_minutes*100
  }
  
  if (length(thldinsp_set$sum_plan_time) == 0 || is.na(thldinsp_set$sum_plan_time)) {
    PTHLDINSP <- 0
    PRATE_HLDINSP <- 0
    PT_PERCENT_HLDINSP <- 0
  } else {
    PTHLDINSP <- thldinsp_set$sum_plan_time
    PRATE_HLDINSP <- planAM/PTHLDINSP*60
    PT_PERCENT_HLDINSP <- PTHLDINSP/total_plan_minutes*100
  }
  
  if (length(tdld_set$sum_plan_time) == 0 || is.na(tdld_set$sum_plan_time)) {
    PTDLD <- 0
    PRATE_DLD <- 0
    PT_PERCENT_DLD <- 0
  } else {
    PTDLD <- tdld_set$sum_plan_time
    PRATE_DLD <- planAM/PTDLD*60
    PT_PERCENT_DLD <- PTDLD/total_plan_minutes*100
  }
  
  if (length(tdldr_set$sum_plan_time) == 0 || is.na(tdldr_set$sum_plan_time)) {
    PTDLDR <- 0
    PRATE_DLDR <- 0
    PT_PERCENT_DLDR <- 0
  } else {
    PTDLDR <- tdldr_set$sum_plan_time
    PRATE_DLDR <- planAM/PTDLDR*60
    PT_PERCENT_DLDR <- PTDLDR/total_plan_minutes*100
  }
  
  if (length(ttd_set$sum_plan_time) == 0 || is.na(ttd_set$sum_plan_time)) {
    PTTD <- 0
    PRATE_TD <- 0
    PT_PERCENT_TD <- 0
  } else {
    PTTD <- ttd_set$sum_plan_time
    PRATE_TD <- planAM/PTTD*60
    PT_PERCENT_TD <- PTTD/total_plan_minutes*100
  }
  
  if (length(tdldinsp_set$sum_plan_time) == 0 || is.na(tdldinsp_set$sum_plan_time)) {
    PTDLDINSP <- 0
    PRATE_DLDINSP <- 0
    PT_PERCENT_DLDINSP <- 0
  } else {
    PTDLDINSP <- tdldinsp_set$sum_plan_time
    PRATE_DLDINSP <- planAM/PTDLDINSP*60
    PT_PERCENT_DLDINSP <- PTDLDINSP/total_plan_minutes*100
  }
  
  if (length(tcode_set$sum_plan_time) == 0 || is.na(tcode_set$sum_plan_time)) {
    PTCODE <- 0
    PRATE_CODE <- 0
    PT_PERCENT_CODE <- 0
  } else {
    PTCODE <- tcode_set$sum_plan_time
    PRATE_CODE <- planAM/PTCODE*60
    PT_PERCENT_CODE <- PTCODE/total_plan_minutes*100
  }
  
  if (length(tcr_set$sum_plan_time) == 0 || is.na(tcr_set$sum_plan_time)) {
    PTCR <- 0
    PRATE_CR <- 0
    PT_PERCENT_CR <- 0
  } else {
    PTCR <- tcr_set$sum_plan_time
    PRATE_CR <- planAM/PTCR*60
    PT_PERCENT_CR <- PTCR/total_plan_minutes*100
  }
  
  if (length(tcompile_set$sum_plan_time) == 0 || is.na(tcompile_set$sum_plan_time)) {
    PTCOMPILE <- 0
    PRATE_COMPILE <- 0
    PT_PERCENT_COMPILE <- 0
  } else {
    PTCOMPILE <- tcompile_set$sum_plan_time
    PRATE_COMPILE <- planAM/PTCOMPILE*60
    PT_PERCENT_COMPILE <- PTCOMPILE/total_plan_minutes*100
  }
  
  if (length(tinsp_set$sum_plan_time) == 0 || is.na(tinsp_set$sum_plan_time)) {
    PTINSP <- 0
    PRATE_INSP <- 0
    PT_PERCENT_INSP <- 0
  } else {
    PTINSP <- tinsp_set$sum_plan_time
    PRATE_INSP <- planAM/PTINSP*60
    PT_PERCENT_INSP <- PTINSP/total_plan_minutes*100
  }
  
  if (length(tut_set$sum_plan_time) == 0 || is.na(tut_set$sum_plan_time)) {
    PTUT <- 0
    PRATE_UT <- 0
    PT_PERCENT_UT <- 0
  } else {
    PTUT <- tut_set$sum_plan_time
    PRATE_UT <- planAM/PTUT*60
    PT_PERCENT_UT <- PTUT/total_plan_minutes*100
  }
  
  if (length(tbit_set$sum_plan_time) == 0 || is.na(tbit_set$sum_plan_time)) {
    PTBIT <- 0
    PRATE_BIT <- 0
    PT_PERCENT_BIT <- 0
  } else {
    PTBIT <- tbit_set$sum_plan_time
    PRATE_BIT <- planAM/PTBIT*60
    PT_PERCENT_BIT <- PTBIT/total_plan_minutes*100
  }
  
  if (length(tst_set$sum_plan_time) == 0 || is.na(tst_set$sum_plan_time)) {
    PTST <- 0
    PRATE_ST <- 0
    PT_PERCENT_ST <- 0
  } else {
    PTST <- tst_set$sum_plan_time
    PRATE_ST <- planAM/PTST*60
    PT_PERCENT_ST <- PTST/total_plan_minutes*100
  }
  
  if (length(tdoc_set$sum_plan_time) == 0 || is.na(tdoc_set$sum_plan_time)) {
    PTDOC <- 0
    PRATE_DOC <- 0
    PT_PERCENT_DOC <- 0
  } else {
    PTDOC <- tdoc_set$sum_plan_time
    PRATE_DOC <- planAM/PTDOC*60
    PT_PERCENT_DOC <- PTDOC/total_plan_minutes*100
  }
  
  if (length(tpm_set$sum_plan_time) == 0 || is.na(tpm_set$sum_plan_time)) {
    PTPM <- 0
    PRATE_PM <- 0
    PT_PERCENT_PM <- 0
  } else {
    PTPM <- tpm_set$sum_plan_time
    PRATE_PM <- planAM/PTPM*60
    PT_PERCENT_PM <- PTPM/total_plan_minutes*100
  }
  
  if (length(tat_set$sum_plan_time) == 0 || is.na(tat_set$sum_plan_time)) {
    PTAT <- 0
    PRATE_AT <- 0
    PT_PERCENT_AT <- 0
  } else {
    PTAT <- tat_set$sum_plan_time
    PRATE_AT <- planAM/PTAT*60
    PT_PERCENT_AT <- PTAT/total_plan_minutes*100
  }
  
  if (length(tpl_set$sum_plan_time) == 0 || is.na(tpl_set$sum_plan_time)) {
    PTPL <- 0
    PRATE_PL <- 0
    PT_PERCENT_PL <- 0
  } else {
    PTPL <- tpl_set$sum_plan_time
    PRATE_PL <- planAM/PTPL*60
    PT_PERCENT_PL <- PTPL/total_plan_minutes*100
  }
  
  PTTOTAL <- sum(time_info$sum_plan_time, na.rm=TRUE)

  # Extract Actual Time in Phase, Actual Phase Rate, and  Actual Time Percent in Phase        
  if (length(tmm_set$sum_actual_time) == 0 || is.na(tmm_set$sum_actual_time)) {
    ATMM <- 0
    ARATE_MM <- 0
    AT_PERCENT_MM <- 0
  } else {
    ATMM <- tmm_set$sum_actual_time
    ARATE_MM <- planAM/ATMM*60
    AT_PERCENT_MM <- ATMM/total_actual_minutes*100
  }
  
  if (length(tls_set$sum_actual_time) == 0 || is.na(tls_set$sum_actual_time)) {
    ATLS <- 0
    ARATE_LS <- 0
    AT_PERCENT_LS <- 0
  } else {
    ATLS <- tls_set$sum_actual_time
    ARATE_LS <- planAM/ATLS*60
    AT_PERCENT_LS <- ATLS/total_actual_minutes*100
  }
  
  if (length(tplan_set$sum_actual_time) == 0 || is.na(tplan_set$sum_actual_time)) {
    ATPLAN <- 0
    ARATE_PLAN <- 0
    AT_PERCENT_PLAN <- 0
  } else {
    ATPLAN <- tplan_set$sum_actual_time
    ARATE_PLAN <- planAM/ATPLAN*60
    AT_PERCENT_PLAN <- ATPLAN/total_actual_minutes*100
  }
  
  if (length(treq_set$sum_actual_time) == 0 || is.na(treq_set$sum_actual_time)) {
    ATREQ <- 0
    ARATE_REQ <- 0
    AT_PERCENT_REQ <- 0
  } else {
    ATREQ <- treq_set$sum_actual_time
    ARATE_REQ <- planAM/ATREQ*60
    AT_PERCENT_REQ <- ATREQ/total_actual_minutes*100
    phase_vector[length(phase_vector)+1] = "Req"
  }
  
  if (length(tstp_set$sum_actual_time) == 0 || is.na(tstp_set$sum_actual_time)) {
    ATSTP <- 0
    ARATE_STP <- 0
    AT_PERCENT_STP <- 0
  } else {
    ATSTP <- tstp_set$sum_actual_time
    ARATE_STP <- planAM/ATSTP*60
    AT_PERCENT_STP <- ATSTP/total_actual_minutes*100
  }
  
  if (length(treqinsp_set$sum_actual_time) == 0 || is.na(treqinsp_set$sum_actual_time)) {
    ATREQINSP <- 0
    ARATE_REQINSP <- 0
    AT_PERCENT_REQINSP <- 0
  } else {
    ATREQINSP <- treqinsp_set$sum_actual_time
    ARATE_REQINSP <- planAM/ATREQINSP*60
    AT_PERCENT_REQINSP <- ATREQINSP/total_actual_minutes*100
  }
  
  if (length(thld_set$sum_actual_time) == 0 || is.na(thld_set$sum_actual_time)) {
    ATHLD <- 0
    ARATE_HLD <- 0
    AT_PERCENT_HLD <- 0
  } else {  
    ATHLD <- thld_set$sum_actual_time
    ARATE_HLD <- planAM/ATHLD*60
    AT_PERCENT_HLD <- ATHLD/total_actual_minutes*100
    phase_vector[length(phase_vector)+1] = "HLD"
  }
  
  if (length(titp_set$sum_actual_time) == 0 || is.na(titp_set$sum_actual_time)) {
    ATITP <- 0
    ARATE_ITP <- 0
    AT_PERCENT_ITP <- 0
  } else {
    ATITP <- titp_set$sum_actual_time
    ARATE_ITP <- planAM/ATITP*60
    AT_PERCENT_ITP <- ATITP/total_actual_minutes*100
  }
  
  if (length(thldinsp_set$sum_actual_time) == 0 || is.na(thldinsp_set$sum_actual_time)) {
    ATHLDINSP <- 0
    ARATE_HLDINSP <- 0
    AT_PERCENT_HLDINSP <- 0
  } else {
    ATHLDINSP <- thldinsp_set$sum_actual_time
    ARATE_HLDINSP <- planAM/ATHLDINSP*60
    AT_PERCENT_HLDINSP <- ATHLDINSP/total_actual_minutes*100
  }
  
  if (length(tdld_set$sum_actual_time) == 0 || is.na(tdld_set$sum_actual_time)) {
    ATDLD <- 0
    ARATE_DLD <- 0
    AT_PERCENT_DLD <- 0
  } else {
    ATDLD <- tdld_set$sum_actual_time
    ARATE_DLD <- planAM/ATDLD*60
    AT_PERCENT_DLD <- ATDLD/total_actual_minutes*100
    phase_vector[length(phase_vector)+1] = "DLD"
  }
  
  if (length(tdldr_set$sum_actual_time) == 0 || is.na(tdldr_set$sum_actual_time)) {
    ATDLDR <- 0
    ARATE_DLDR <- 0
    AT_PERCENT_DLDR <- 0
  } else {
    ATDLDR <- tdldr_set$sum_actual_time
    ARATE_DLDR <- planAM/ATDLDR*60
    AT_PERCENT_DLDR <- ATDLDR/total_actual_minutes*100
  }
  
  if (length(ttd_set$sum_actual_time) == 0 || is.na(ttd_set$sum_actual_time)) {
    ATTD <- 0
    ARATE_TD <- 0
    AT_PERCENT_TD <- 0
  } else {
    ATTD <- ttd_set$sum_actual_time
    ARATE_TD <- planAM/ATTD*60
    AT_PERCENT_TD <- ATTD/total_actual_minutes*100
  }
  
  if (length(tdldinsp_set$sum_actual_time) == 0 || is.na(tdldinsp_set$sum_actual_time)) {
    ATDLDINSP <- 0
    ARATE_DLDINSP <- 0
    AT_PERCENT_DLDINSP <- 0
  } else {
    ATDLDINSP <- tdldinsp_set$sum_actual_time
    ARATE_DLDINSP <- planAM/ATDLDINSP*60
    AT_PERCENT_DLDINSP <- ATDLDINSP/total_actual_minutes*100
  }
  
  if (length(tcode_set$sum_actual_time) == 0 || is.na(tcode_set$sum_actual_time)) {
    ATCODE <- 0
    ARATE_CODE <- 0
    AT_PERCENT_CODE <- 0
  } else {
    ATCODE <- tcode_set$sum_actual_time
    ARATE_CODE <- planAM/ATCODE*60
    AT_PERCENT_CODE <- ATCODE/total_actual_minutes*100
    phase_vector[length(phase_vector)+1] = "Code"
  }
  
  if (length(tcr_set$sum_actual_time) == 0 || is.na(tcr_set$sum_actual_time)) {
    ATCR <- 0
    ARATE_CR <- 0
    AT_PERCENT_CR <- 0
  } else {
    ATCR <- tcr_set$sum_actual_time
    ARATE_CR <- planAM/ATCR*60
    AT_PERCENT_CR <- ATCR/total_actual_minutes*100
  }
  
  if (length(tcompile_set$sum_actual_time) == 0 || is.na(tcompile_set$sum_actual_time)) {
    ATCOMPILE <- 0
    ARATE_COMPILE <- 0
    AT_PERCENT_COMPILE <- 0
  } else {
    ATCOMPILE <- tcompile_set$sum_actual_time
    ARATE_COMPILE <- planAM/ATCOMPILE*60
    AT_PERCENT_COMPILE <- ATCOMPILE/total_actual_minutes*100
    phase_vector[length(phase_vector)+1] = "Compile"
  }
  
  if (length(tinsp_set$sum_actual_time) == 0 || is.na(tinsp_set$sum_actual_time)) {
    ATINSP <- 0
    ARATE_INSP <- 0
    AT_PERCENT_INSP <- 0
  } else {
    ATINSP <- tinsp_set$sum_actual_time
    ARATE_INSP <- planAM/ATINSP*60
    AT_PERCENT_INSP <- ATINSP/total_actual_minutes*100
  }
  
  if (length(tut_set$sum_actual_time) == 0 || is.na(tut_set$sum_actual_time)) {
    ATUT <- 0
    ARATE_UT <- 0
    AT_PERCENT_UT <- 0
  } else {
    ATUT <- tut_set$sum_actual_time
    ARATE_UT <- planAM/ATUT*60
    AT_PERCENT_UT <- ATUT/total_actual_minutes*100
    phase_vector[length(phase_vector)+1] = "UT"
  }
  
  if (length(tbit_set$sum_actual_time) == 0 || is.na(tbit_set$sum_actual_time)) {
    ATBIT <- 0
    ARATE_BIT <- 0
    AT_PERCENT_BIT <- 0
  } else {
    ATBIT <- tbit_set$sum_actual_time
    ARATE_BIT <- planAM/ATBIT*60
    AT_PERCENT_BIT <- ATBIT/total_actual_minutes*100
    phase_vector[length(phase_vector)+1] = "BIT"
  }
  
  if (length(tst_set$sum_actual_time) == 0 || is.na(tst_set$sum_actual_time)) {
    ATST <- 0
    ARATE_ST <- 0
    AT_PERCENT_ST <- 0
  } else {
    ATST <- tst_set$sum_actual_time
    ARATE_ST <- planAM/ATST*60
    AT_PERCENT_ST <- ATST/total_actual_minutes*100
    phase_vector[length(phase_vector)+1] = "ST"
  }
  
  if (length(tdoc_set$sum_actual_time) == 0 || is.na(tdoc_set$sum_actual_time)) {
    ATDOC <- 0
    ARATE_DOC <- 0
    AT_PERCENT_DOC <- 0
  } else {
    ATDOC <- tdoc_set$sum_actual_time
    ARATE_DOC <- planAM/ATDOC*60
    AT_PERCENT_DOC <- ATDOC/total_actual_minutes*100
  }
  
  if (length(tpm_set$sum_actual_time) == 0 || is.na(tpm_set$sum_actual_time)) {
    ATPM <- 0
    ARATE_PM <- 0
    AT_PERCENT_PM <- 0
  } else {
    ATPM <- tpm_set$sum_actual_time
    ARATE_PM <- planAM/ATPM*60
    AT_PERCENT_PM <- ATPM/total_actual_minutes*100
  }
  
  if (length(tat_set$sum_actual_time) == 0 || is.na(tat_set$sum_actual_time)) {
    ATAT <- 0
    ARATE_AT <- 0
    AT_PERCENT_AT <- 0
  } else {
    ATAT <- tat_set$sum_actual_time
    ARATE_AT <- planAM/ATAT*60
    AT_PERCENT_AT <- ATAT/total_actual_minutes*100
    #phase_vector[length(phase_vector)+1] = "AT"
  }
  
  if (length(tpl_set$sum_actual_time) == 0 || is.na(tpl_set$sum_actual_time)) {
    ATPL <- 0
    ARATE_PL <- 0
    AT_PERCENT_PL <- 0
  } else {
    ATPL <- tpl_set$sum_actual_time
    ARATE_PL <- planAM/ATPL*60
    AT_PERCENT_PL <- ATPL/total_actual_minutes*100
  }
  
  ATTOTAL <- sum(time_info$sum_actual_time, na.rm=TRUE)
  
  ## Actual Defect Density
  if (actualAM == 0) {
    DDDLDR <- 0
    DDDLDINSP <- 0
    DDCR <- 0
    DDCOMPILE <- 0
    DDINSP <- 0
    DDUT <- 0
    DDBIT <- 0
    DDST <- 0
    DDTOTAL <- 0
  } else {
    DDDLDR <- ADRDLDR/actualAM
    DDDLDINSP <- ADRDLDINSP/actualAM
    DDCR <- ADRCR/actualAM
    DDCOMPILE <- ADRCOMPILE/actualAM
    DDINSP <- ADRINSP/actualAM
    DDUT <- ADRUT/actualAM
    DDBIT <- ADRBIT/actualAM
    DDST <- ADRST/actualAM
    DDTOTAL <- ADRTOTAL/actualAM
  }
  
  ## Plan Defect Injection and Removal Rates
  # Plan Defect Injection Rates
  PDINJ_RATE_PLAN <- NoData
  PDINJ_RATE_REQ <- NoData
  PDINJ_RATE_STP <- NoData
  PDINJ_RATE_REQINSP <- NoData
  PDINJ_RATE_HLD <- NoData
  PDINJ_RATE_ITP <- NoData
  PDINJ_RATE_HLDINSP <- NoData
  PDINJ_RATE_DLD <- NoData
  PDINJ_RATE_DLDR <- NoData
  PDINJ_RATE_TD <- NoData
  PDINJ_RATE_DLDINSP <- NoData
  PDINJ_RATE_CODE <- NoData
  PDINJ_RATE_CR <- NoData
  PDINJ_RATE_COMPILE <- NoData
  PDINJ_RATE_INSP <- NoData
  PDINJ_RATE_UT <- NoData
  PDINJ_RATE_BIT <- NoData
  PDINJ_RATE_ST <- NoData
  PDINJ_RATE_AT <- NoData
  PDINJ_RATE_PL <- NoData
  PDINJ_RATE_TOTAL <- NoData
  
  # Plan Defect Removal Rates
  PDREM_RATE_PLAN <- NoData
  PDREM_RATE_REQ <- NoData
  PDREM_RATE_STP <- NoData
  PDREM_RATE_REQINSP <- NoData
  PDREM_RATE_HLD <- NoData
  PDREM_RATE_ITP <- NoData
  PDREM_RATE_HLDINSP <- NoData
  PDREM_RATE_DLD <- NoData
  PDREM_RATE_DLDR <- NoData
  PDREM_RATE_TD <- NoData
  PDREM_RATE_DLDINSP <- NoData
  PDREM_RATE_CODE <- NoData
  PDREM_RATE_CR <- NoData
  PDREM_RATE_COMPILE <- NoData
  PDREM_RATE_INSP <- NoData
  PDREM_RATE_UT <- NoData
  PDREM_RATE_BIT <- NoData
  PDREM_RATE_ST <- NoData
  PDREM_RATE_AT <- NoData
  PDREM_RATE_PL <- NoData
  PDREM_RATE_TOTAL <- NoData
  
  # Actual Defect Injection and Removal Rates
  if (ATPLAN == 0) {
    ADINJ_RATE_PLAN <- 0
    ADREM_RATE_PLAN <- 0
  } else {
    ADINJ_RATE_PLAN <- ADIPLAN/ATPLAN*60
    ADREM_RATE_PLAN <- ADRPLAN/ATPLAN*60
  }

  if (ATREQ == 0) {
    ADINJ_RATE_REQ <- 0
    ADREM_RATE_REQ <- 0
  } else {
    ADINJ_RATE_REQ <- ADIREQ/ATREQ*60
    ADREM_RATE_REQ <- ADRREQ/ATREQ*60
  }
  
  if (ATSTP == 0) {
    ADINJ_RATE_STP <- 0
    ADREM_RATE_STP <- 0
  } else {
    ADINJ_RATE_STP <- ADISTP/ATSTP*60
    ADREM_RATE_STP <- ADRSTP/ATSTP*60
  }
  
  if (ATREQINSP == 0) {
    ADINJ_RATE_REQINSP <- 0
    ADREM_RATE_REQINSP <- 0
  } else {
    ADINJ_RATE_REQINSP <- ADIREQINSP/ATREQINSP*60
    ADREM_RATE_REQINSP <- ADRREQINSP/ATREQINSP*60
  }
  
  if (ATHLD == 0) {
    ADINJ_RATE_HLD <- 0
    ADREM_RATE_HLD <- 0
  } else {
    ADINJ_RATE_HLD <- ADIHLD/ATHLD*60
    ADREM_RATE_HLD <- ADRHLD/ATHLD*60
  }
  
  if (ATITP == 0) {
    ADINJ_RATE_ITP <- 0
    ADREM_RATE_ITP <- 0
  } else {
    ADINJ_RATE_ITP <- ADIITP/ATITP*60
    ADREM_RATE_ITP <- ADRITP/ATITP*60
  }
  
  if (ATHLDINSP == 0) {
    ADINJ_RATE_HLDINSP <- 0
    ADREM_RATE_HLDINSP <- 0
  } else {
    ADINJ_RATE_HLDINSP <- ADIHLDINSP/ATHLDINSP*60
    ADREM_RATE_HLDINSP <- ADRHLDINSP/ATHLDINSP*60
  }
  
  if (ATDLD == 0) {
    ADINJ_RATE_DLD <- 0
    ADREM_RATE_DLD <- 0
  } else {
    ADINJ_RATE_DLD <- ADIDLD/ATDLD*60
    ADREM_RATE_DLD <- ADRDLD/ATDLD*60
  }
  
  if (ATDLDR == 0) {
    ADINJ_RATE_DLDR <- 0
    ADREM_RATE_DLDR <- 0
  } else {
    ADINJ_RATE_DLDR <- ADIDLDR/ATDLDR*60
    ADREM_RATE_DLDR <- ADRDLDR/ATDLDR*60
  }
  
  if (ATTD == 0) {
    ADINJ_RATE_TD <- 0
    ADREM_RATE_TD <- 0
  } else {
    ADINJ_RATE_TD <- ADITD/ATTD*60
    ADREM_RATE_TD <- ADRTD/ATTD*60
  }
  
  if (ATDLDINSP == 0) {
    ADINJ_RATE_DLDINSP <- 0
    ADREM_RATE_DLDINSP <- 0
  } else {
    ADINJ_RATE_DLDINSP <- ADIDLDINSP/ATDLDINSP*60
    ADREM_RATE_DLDINSP <- ADRDLDINSP/ATDLDINSP*60
  }
  
  if (ATCODE == 0) {
    ADINJ_RATE_CODE <- 0
    ADREM_RATE_CODE <- 0
  } else {
    ADINJ_RATE_CODE <- ADICODE/ATCODE*60
    ADREM_RATE_CODE <- ADRCODE/ATCODE*60
  }
  
  if (ATCR == 0) {
    ADINJ_RATE_CR <- 0
    ADREM_RATE_CR <- 0
  } else {
    ADINJ_RATE_CR <- ADICR/ATCR*60
    ADREM_RATE_CR <- ADRCR/ATCR*60
  }
  
  if (ATCOMPILE == 0) {
    ADINJ_RATE_COMPILE <- 0
    ADREM_RATE_COMPILE <- 0
  } else {
    ADINJ_RATE_COMPILE <- ADICOMPILE/ATCOMPILE*60
    ADREM_RATE_COMPILE <- ADRCOMPILE/ATCOMPILE*60
  }
  
  if (ATINSP == 0) {
    ADINJ_RATE_INSP <- 0
    ADREM_RATE_INSP <- 0
  } else {
    ADINJ_RATE_INSP <- ADIINSP/ATINSP*60
    ADREM_RATE_INSP <- ADRINSP/ATINSP*60
  }
  
  if (ATUT == 0) {
    ADINJ_RATE_UT <- 0
    ADREM_RATE_UT <- 0
  } else {
    ADINJ_RATE_UT <- ADIUT/ATUT*60
    ADREM_RATE_UT <- ADRUT/ATUT*60
  }
  
  if (ATBIT == 0) {
    ADINJ_RATE_BIT <- 0
    ADREM_RATE_BIT <- 0
  } else {
    ADINJ_RATE_BIT <- ADIBIT/ATBIT*60
    ADREM_RATE_BIT <- ADRBIT/ATBIT*60
  }
  
  if (ATST == 0) {
    ADINJ_RATE_ST <- 0
    ADREM_RATE_ST <- 0
  } else {
    ADINJ_RATE_ST <- ADIST/ATST*60
    ADREM_RATE_ST <- ADRST/ATST*60
  }
  
  if (ATPL == 0) {
    ADINJ_RATE_PL <- 0
    ADREM_RATE_PL <- 0
  } else {
    ADINJ_RATE_PL <- ADIPL/ATPL*60
    ADREM_RATE_PL <- ADRPL/ATPL*60
  }
  
  if (ATAT == 0) {
    ADINJ_RATE_AT <- 0
    ADREM_RATE_AT <- 0
  } else {
    ADINJ_RATE_AT <- ADIAT/ATAT*60
    ADREM_RATE_AT <- ADRAT/ATAT*60
  }
  
  if (ATTOTAL == 0) {
    ADINJ_RATE_TOTAL <- 0
    ADREM_RATE_TOTAL <- 0
  } else {
    ADINJ_RATE_TOTAL <- ADITOTAL/total_actual_minutes*60
    ADREM_RATE_TOTAL <- ADRTOTAL/total_actual_minutes*60
  }
  
  ## Development Phase Effort Ratio
  if (ATREQ == 0) {
    TRREQINSP2REQ <- 0
  } else {
    TRREQINSP2REQ <- ATREQINSP/ATREQ
  }
  
  if (ATHLD == 0) {
    TRHLDINSP2HLD <- 0
  } else {
    TRHLDINSP2HLD <- ATHLDINSP/ATHLD
  }
  
  if (ATDLD == 0) {
    TRDLDINSP2DLD <- 0
  } else {
    TRDLDINSP2DLD <- ATDLDINSP/ATDLD
  }
  
  if (ATDLD == 0) {
    TRDLDR2DLD <- 0
  } else {
    TRDLDR2DLD <- ATDLDR/ATDLD
  }
  
  if (ATCODE == 0) {
    TRCODEINSP2CODE <- 0
  } else {
    TRCODEINSP2CODE <- ATINSP/ATCODE
  }
  
  if (ATCODE == 0) {
    TRCR2CODE <- 0
  } else {
    TRCR2CODE <- ATCR/ATCODE
  }
  
  if (ATCODE == 0) {
    TRDESGN2CODE <- 0
  } else {
    TRDESGN2CODE <- (ATHLD+ATDLD)/ATCODE
  }
  
  ## Defect Removal Phase Yield Parameters
  # Plan Defect Removal Phase Yield Parameters
  PDREM_YIELD_PLAN <- NoData
  PDREM_YIELD_REQ <- NoData
  PDREM_YIELD_STP <- NoData
  PDREM_YIELD_REQINSP <- NoData
  PDREM_YIELD_HLD <- NoData
  PDREM_YIELD_ITP <- NoData
  PDREM_YIELD_HLDINSP <- NoData
  PDREM_YIELD_DLD <- NoData
  PDREM_YIELD_DLDR <- NoData
  PDREM_YIELD_TD <- NoData
  PDREM_YIELD_DLDINSP <- NoData
  PDREM_YIELD_CODE <- NoData
  PDREM_YIELD_CR <- NoData
  PDREM_YIELD_COMPILE <- NoData
  PDREM_YIELD_INSP <- NoData
  PDREM_YIELD_UT <- NoData
  PDREM_YIELD_BIT <- NoData
  PDREM_YIELD_ST <- NoData
  PDREM_YIELD_AT <- NoData
  PDREM_YIELD_PL <- NoData
  
  # Actual Defect Removal Phase Yield Parameters
  sum_defect_plan <- ADIPLAN
  sum_defect_req <- sum_defect_plan+ADIREQ-ADRPLAN
  sum_defect_stp <- sum_defect_req+ADISTP-ADRREQ
  sum_defect_reqinsp <- sum_defect_stp+ADIREQR+ADIREQINSP-ADRSTP-ADRREQR
  sum_defect_hld <- sum_defect_reqinsp+ADIHLD-ADRREQINSP
  sum_defect_itp <- sum_defect_hld+ADIITP-ADRHLD
  sum_defect_hldinsp <- sum_defect_itp+ADIHLDR+ADIHLDINSP-ADRITP-ADRHLDR
  sum_defect_dld <-sum_defect_hldinsp+ADIDLD-ADRHLDINSP
  sum_defect_dldr <- sum_defect_dld+ADIDLDR-ADRDLD
  sum_defect_td <- sum_defect_dldr+ADITD-ADRDLDR
  sum_defect_dldinsp <- sum_defect_td+ADRDLDINSP-ADRTD
  sum_defect_code <- sum_defect_dldinsp+ADICODE-ADRDLDINSP
  sum_defect_cr <- sum_defect_code+ADICR-ADRCODE
  sum_defect_compile <- sum_defect_cr+ADICOMPILE-ADRCR
  sum_defect_insp <- sum_defect_compile+ADIINSP-ADRCOMPILE
  sum_defect_ut <- sum_defect_insp+ADIUT-ADRINSP
  sum_defect_bit <- sum_defect_ut+ADIBIT-ADRUT
  sum_defect_st <- sum_defect_bit+ADIST-ADRBIT
  sum_defect_at <- sum_defect_st+ADIAT-ADRST
  sum_defect_pl <- sum_defect_at+ADIPL-ADRAT
  
  if (length(sum_defect_plan) == 0) {
    ADREM_YIELD_PLAN <- NoData
  } else {
    ADREM_YIELD_PLAN <- (ADRPLAN/sum_defect_plan)*100
  }
  
  if (length(sum_defect_req) == 0) {
    ADREM_YIELD_REQ <- NoData
  } else {
    ADREM_YIELD_REQ <- (ADRREQ/sum_defect_req)*100
  }
  
  if (length(sum_defect_stp) == 0) {
    ADREM_YIELD_STP <- NoData
  } else {
    ADREM_YIELD_STP <- (ADRSTP/sum_defect_stp)*100
  }
  
  if (length(sum_defect_reqinsp) == 0) {
    ADREM_YIELD_REQINSP <- NoData
  } else {
    ADREM_YIELD_REQINSP <- (ADRREQINSP/sum_defect_reqinsp)*100
  }
  
  if (length(sum_defect_hld) == 0) {
    ADREM_YIELD_HLD <- NoData
  } else {
    ADREM_YIELD_HLD <- (ADRHLD/sum_defect_hld)*100
  }
  
  if (length(sum_defect_itp) == 0) {
    ADREM_YIELD_ITP <- NoData
  } else {
    ADREM_YIELD_ITP <- (ADRITP/sum_defect_itp)*100
  }
  
  if (length(sum_defect_hldinsp) == 0) {
    ADREM_YIELD_HLDINSP <- NoData
  } else {
    ADREM_YIELD_HLDINSP <- (ADRHLDINSP/sum_defect_hldinsp)*100
  }
  
  if (length(sum_defect_dld) == 0) {
    ADREM_YIELD_DLD <- NoData
  } else {
    ADREM_YIELD_DLD <- (ADRDLD/sum_defect_reqinsp)*100
  }
  
  if (length(sum_defect_dldr) == 0) {
    ADREM_YIELD_DLDR <- NoData
  } else {
    ADREM_YIELD_DLDR <- (ADRDLDR/sum_defect_dldr)*100
  }
  
  if (length(sum_defect_td) == 0) {
    ADREM_YIELD_TD <- NoData
  } else {
    ADREM_YIELD_TD <- (ADRTD/sum_defect_td)*100
  }
  
  if (length(sum_defect_dldinsp) == 0) {
    ADREM_YIELD_DLDINSP <- NoData
  } else {
    ADREM_YIELD_DLDINSP <- (ADRDLDINSP/sum_defect_dldinsp)*100
  }
  
  if (length(sum_defect_code) == 0) {
    ADREM_YIELD_CODE <- NoData
  } else {
    ADREM_YIELD_CODE <- (ADRCODE/sum_defect_code)*100
  }
  
  if (length(sum_defect_cr) == 0) {
    ADREM_YIELD_CR <- NoData
  } else {
    ADREM_YIELD_CR <- (ADRCR/sum_defect_cr)*100
  }
  
  if (length(sum_defect_compile) == 0) {
    ADREM_YIELD_COMPILE <- NoData
  } else {
    ADREM_YIELD_COMPILE <- (ADRCOMPILE/sum_defect_compile)*100
  }
  
  if (length(sum_defect_insp) == 0) {
    ADREM_YIELD_INSP <- NoData
  } else {
    ADREM_YIELD_INSP <- (ADRINSP/sum_defect_insp)*100
  }
  
  if (length(sum_defect_ut) == 0) {
    ADREM_YIELD_UT <- NoData
  } else {
    ADREM_YIELD_UT <- (ADRUT/sum_defect_ut)*100
  }
  
  if (length(sum_defect_bit) == 0) {
    ADREM_YIELD_BIT <- NoData
  } else {
    ADREM_YIELD_BIT <- (ADRBIT/sum_defect_bit)*100
  }
  
  if (length(sum_defect_st) == 0) {
    ADREM_YIELD_ST <- NoData
  } else {
    ADREM_YIELD_ST <- (ADRST/sum_defect_st)*100
  }
  
  if (length(sum_defect_at) == 0) {
    ADREM_YIELD_AT <- NoData
  } else {
    ADREM_YIELD_AT <- (ADRAT/sum_defect_at)*100
  }
  
  if (length(sum_defect_pl) == 0) {
    ADREM_YIELD_PL <- NoData
  } else {
    ADREM_YIELD_PL <- (ADRPL/sum_defect_pl)*100
  }
  
  ## Plan Defect Removal Effort Per Defect in Test Phaess [Hr/Defect]
  PREMRATE_DEFECT_RATE_UT <- NoData
  PREMRATE_DEFECT_RATE_BIT <- NoData
  PREMRATE_DEFECT_RATE_ST <- NoData
  PREMRATE_DEFECT_RATE_AT <- NoData
  PREMRATE_DEFECT_RATE_PL <- NoData
  
  ## Plan Zero Defect Effort Phases [Hr/Defect]
  PZero_DEFECT_RATE_UT <- NoData
  PZero_DEFECT_RATE_BIT <- NoData
  PZero_DEFECT_RATE_ST <- NoData
  PZero_DEFECT_RATE_AT <- NoData
  PZero_DEFECT_RATE_PL <- NoData
  
  ## Size and Estimation Performance
  AM_Size_Estimation_Accuracy <- actualAM/planAM
  Effort_Estimation_Accuracy <- total_actual_minutes/total_plan_minutes
  Actual_Production_Rate <- actualAM/(total_actual_minutes/60)
  
  # COA,COF,and COQ
  COA_set <- subset(time_info, phase_type=="Appraisal")
  COF_set <- subset(time_info, phase_type=="Failure")
  construction_set <- subset(time_info, phase_type=="Construction")
  construction_effort <- sum(construction_set$sum_actual_time, na.rm=TRUE)/60
  total_effort <- sum(time_info$sum_actual_time, na.rm=TRUE)/60
  
  COA <- sum(COA_set$sum_actual_time, na.rm=TRUE)/60
  COF <- sum(COF_set$sum_actual_time, na.rm=TRUE)/60
  COQ <- COA+COF
  COQPctAppraisal <- COA/construction_effort
  COQPctFailure <- COF/construction_effort
  COQPct <- COQ/construction_effort
  
  COAratio_size <- COA/actualAM
  COFratio_size <- COF/actualAM
  COQratio_size <- COQ/actualAM
  
  AFratio <- COA/COF
  
  # COA,COF, and COQ within DLD through UT
  COAinDLDUT_set <- subset(time_info, phase_short_name=="Design Review" | phase_short_name=="Design Inspect" | phase_short_name=="Code Review" | phase_short_name=="Code Inspect")
  COFinDLDUT_set <- subset(time_info, phase_short_name=="Compile" | phase_short_name=="Test")
  
  COAinDLDUT <- sum(COAinDLDUT_set$sum_actual_time, na.rm=TRUE)/60
  COFinDLDUT <- sum(COFinDLDUT_set$sum_actual_time, na.rm=TRUE)/60
  COQinDLDUT <- COAinDLDUT+COFinDLDUT
  
  COAinDLDUTratio_size <- COAinDLDUT/actualAM
  COFinDLDUTratio_size <- COFinDLDUT/actualAM
  COQinDLDUTratio_size <- COQinDLDUT/actualAM
  
  # Production rate  
  produc_rate_const <- actualAM/construction_effort
  produc_rate_total <- actualAM/total_effort
  
  # execute preprocessing for output

  if (paste(phase_vector, collapse=":") == "") {
    phase_str <- NoData
    phase_top <- NoData
    phase_bottom <- NoData
    phase_top_bottom <- NoData
  } else {
    phase_str <- paste(phase_vector, collapse=":")
    phase_top <- phase_vector[1]
    phase_bottom <- phase_vector[length(phase_vector)]
    phase_top_bottom <- paste(phase_top, phase_bottom, sep=":")
  }
  
  # write project fact data in each column
  writeLines(paste(element), out, sep=",")
  writeLines(paste(org_name), out, sep=",")
  writeLines(paste(wbs_element_name), out, sep=",")
  writeLines(paste(project_key), out, sep=",")
  writeLines(paste(team_key), out, sep=",")
  writeLines(paste(team_size), out, sep=",")
  writeLines(paste(individuals), out, sep=",")
  writeLines(paste(process_name), out, sep=",")
  writeLines(paste(phase_str), out, sep=",")
  writeLines(paste(phase_top), out, sep=",")
  writeLines(paste(phase_bottom), out, sep=",")
  writeLines(paste(phase_top_bottom), out, sep=",")
  writeLines(paste(mean_team_hours_week), out, sep=",")
  writeLines(paste(mean_team_member_hours_week), out, sep=",")
  writeLines(paste(time_benford_mad), out, sep=",")
  writeLines(paste(defect_benford_mad), out, sep=",")    
  writeLines(paste(start_date_char), out, sep=",")
  writeLines(paste(end_date_char), out, sep=",")
  writeLines(paste(plan_date), out, sep=",")
  writeLines(paste(baseline_date), out, sep=",")
  writeLines(paste(predicted_date), out, sep=",")
  writeLines(paste(start_week), out, sep=",")
  writeLines(paste(actual_week), out, sep=",")
  writeLines(paste(plan_weeks), out, sep=",")
  writeLines(paste(baseline_weeks), out, sep=",")
  writeLines(paste(growth_schedule_baseline), out, sep=",")
  writeLines(paste(component_networkdays), out, sep=",")
  writeLines(paste(actual_task_hours), out, sep=",")
  writeLines(paste(plan_task_hours), out, sep=",")
  writeLines(paste(baseline_task_hours), out, sep=",")
  writeLines(paste(component_comp_parts_plan_hours), out, sep=",")
  writeLines(paste(component_comp_parts_actual_hours), out, sep=",")
  writeLines(paste(growth_task_hours_baseline), out, sep=",")
  writeLines(paste(task_estimation_accuracy), out, sep=",")
  #writeLines(paste(CPI), out, sep=",")
  #writeLines(paste(SPI), out, sep=",")
  #writeLines(paste(CV), out, sep=",")
  #writeLines(paste(SV), out, sep=",")
  #writeLines(paste(CumPV), out, sep=",")
  #writeLines(paste(CumEV), out, sep=",")
  #writeLines(paste(Final_EV), out, sep=",")
  writeLines(paste(planB), out, sep=",")
  writeLines(paste(planD), out, sep=",")
  writeLines(paste(planM), out, sep=",")
  writeLines(paste(planA), out, sep=",")
  writeLines(paste(planR), out, sep=",")
  writeLines(paste(planAM), out, sep=",")
  writeLines(paste(planT), out, sep=",")
  writeLines(paste(planNR), out, sep=",")
  writeLines(paste(actualB), out, sep=",")
  writeLines(paste(actualD), out, sep=",")
  writeLines(paste(actualM), out, sep=",")
  writeLines(paste(actualA), out, sep=",")
  writeLines(paste(actualR), out, sep=",")
  writeLines(paste(actualAM), out, sep=",")
  writeLines(paste(actualT), out, sep=",")
  writeLines(paste(actualNR), out, sep=",")
  writeLines(paste(PDIPLAN), out, sep=",")
  writeLines(paste(PDIREQ), out, sep=",")
  writeLines(paste(PDISTP), out, sep=",")
  writeLines(paste(PDIREQINSP), out, sep=",")
  writeLines(paste(PDIHLD), out, sep=",")
  writeLines(paste(PDIITP), out, sep=",")
  writeLines(paste(PDIHLDINSP), out, sep=",")
  writeLines(paste(PDIDLD), out, sep=",")
  writeLines(paste(PDIDLDR), out, sep=",")
  writeLines(paste(PDITD), out, sep=",")
  writeLines(paste(PDIDLDINSP), out, sep=",")
  writeLines(paste(PDICODE), out, sep=",")
  writeLines(paste(PDICR), out, sep=",")
  writeLines(paste(PDICOMPILE), out, sep=",")
  writeLines(paste(PDIINSP), out, sep=",")
  writeLines(paste(PDIUT), out, sep=",")
  writeLines(paste(PDIBIT), out, sep=",")
  writeLines(paste(PDIST), out, sep=",")
  writeLines(paste(PDIAT), out, sep=",")
  writeLines(paste(PDIPL), out, sep=",")
  writeLines(paste(PDITOTAL), out, sep=",")
  writeLines(paste(ADIPLAN), out, sep=",")
  writeLines(paste(ADIREQ), out, sep=",")
  writeLines(paste(ADISTP), out, sep=",")
  writeLines(paste(ADIREQINSP), out, sep=",")
  writeLines(paste(ADIHLD), out, sep=",")
  writeLines(paste(ADIITP), out, sep=",")
  writeLines(paste(ADIHLDINSP), out, sep=",")
  writeLines(paste(ADIDLD), out, sep=",")
  writeLines(paste(ADIDLDR), out, sep=",")
  writeLines(paste(ADITD), out, sep=",")
  writeLines(paste(ADIDLDINSP), out, sep=",")
  writeLines(paste(ADICODE), out, sep=",")
  writeLines(paste(ADICR), out, sep=",")
  writeLines(paste(ADICOMPILE), out, sep=",")
  writeLines(paste(ADIINSP), out, sep=",")
  writeLines(paste(ADIUT), out, sep=",")
  writeLines(paste(ADIBIT), out, sep=",")
  writeLines(paste(ADIST), out, sep=",")
  writeLines(paste(ADIAT), out, sep=",")
  writeLines(paste(ADIPL), out, sep=",")
  writeLines(paste(ADITOTAL), out, sep=",")
  writeLines(paste(PDRPLAN), out, sep=",")
  writeLines(paste(PDRREQ), out, sep=",")
  writeLines(paste(PDRSTP), out, sep=",")
  writeLines(paste(PDRREQINSP), out, sep=",")
  writeLines(paste(PDRHLD), out, sep=",")
  writeLines(paste(PDRITP), out, sep=",")
  writeLines(paste(PDRHLDINSP), out, sep=",")
  writeLines(paste(PDRDLD), out, sep=",")
  writeLines(paste(PDRDLDR), out, sep=",")
  writeLines(paste(PDRTD), out, sep=",")
  writeLines(paste(PDRDLDINSP), out, sep=",")
  writeLines(paste(PDRCODE), out, sep=",")
  writeLines(paste(PDRCR), out, sep=",")
  writeLines(paste(PDRCOMPILE), out, sep=",")
  writeLines(paste(PDRINSP), out, sep=",")
  writeLines(paste(PDRUT), out, sep=",")
  writeLines(paste(PDRBIT), out, sep=",")
  writeLines(paste(PDRST), out, sep=",")
  writeLines(paste(PDRAT), out, sep=",")
  writeLines(paste(PDRPL), out, sep=",")
  writeLines(paste(PDRTOTAL), out, sep=",")
  writeLines(paste(ADRPLAN), out, sep=",")
  writeLines(paste(ADRREQ), out, sep=",")
  writeLines(paste(ADRSTP), out, sep=",")
  writeLines(paste(ADRREQINSP), out, sep=",")
  writeLines(paste(ADRHLD), out, sep=",")
  writeLines(paste(ADRITP), out, sep=",")
  writeLines(paste(ADRHLDINSP), out, sep=",")
  writeLines(paste(ADRDLD), out, sep=",")
  writeLines(paste(ADRDLDR), out, sep=",")
  writeLines(paste(ADRTD), out, sep=",")
  writeLines(paste(ADRDLDINSP), out, sep=",")
  writeLines(paste(ADRCODE), out, sep=",")
  writeLines(paste(ADRCR), out, sep=",")
  writeLines(paste(ADRCOMPILE), out, sep=",")
  writeLines(paste(ADRINSP), out, sep=",")
  writeLines(paste(ADRUT), out, sep=",")
  writeLines(paste(ADRBIT), out, sep=",")
  writeLines(paste(ADRST), out, sep=",")
  writeLines(paste(ADRAT), out, sep=",")
  writeLines(paste(ADRPL), out, sep=",")
  writeLines(paste(ADRTOTAL), out, sep=",")
  writeLines(paste(PTMM), out, sep=",")
  writeLines(paste(PTLS), out, sep=",")
  writeLines(paste(PTPLAN), out, sep=",")
  writeLines(paste(PTREQ), out, sep=",")
  writeLines(paste(PTSTP), out, sep=",")
  writeLines(paste(PTREQINSP), out, sep=",")
  writeLines(paste(PTHLD), out, sep=",")
  writeLines(paste(PTITP), out, sep=",")
  writeLines(paste(PTHLDINSP), out, sep=",")
  writeLines(paste(PTDLD), out, sep=",")
  writeLines(paste(PTDLDR), out, sep=",")
  writeLines(paste(PTTD), out, sep=",")
  writeLines(paste(PTDLDINSP), out, sep=",")
  writeLines(paste(PTCODE), out, sep=",")
  writeLines(paste(PTCR), out, sep=",")
  writeLines(paste(PTCOMPILE), out, sep=",")
  writeLines(paste(PTINSP), out, sep=",")
  writeLines(paste(PTUT), out, sep=",")
  writeLines(paste(PTBIT), out, sep=",")
  writeLines(paste(PTST), out, sep=",")
  writeLines(paste(PTDOC), out, sep=",")
  writeLines(paste(PTPM), out, sep=",")
  writeLines(paste(PTAT), out, sep=",")
  writeLines(paste(PTPL), out, sep=",")
  writeLines(paste(PTTOTAL), out, sep=",")
  writeLines(paste(ATMM), out, sep=",")
  writeLines(paste(ATLS), out, sep=",")
  writeLines(paste(ATPLAN), out, sep=",")
  writeLines(paste(ATREQ), out, sep=",")
  writeLines(paste(ATSTP), out, sep=",")
  writeLines(paste(ATREQINSP), out, sep=",")
  writeLines(paste(ATHLD), out, sep=",")
  writeLines(paste(ATITP), out, sep=",")
  writeLines(paste(ATHLDINSP), out, sep=",")
  writeLines(paste(ATDLD), out, sep=",")
  writeLines(paste(ATDLDR), out, sep=",")
  writeLines(paste(ATTD), out, sep=",")
  writeLines(paste(ATDLDINSP), out, sep=",")
  writeLines(paste(ATCODE), out, sep=",")
  writeLines(paste(ATCR), out, sep=",")
  writeLines(paste(ATCOMPILE), out, sep=",")
  writeLines(paste(ATINSP), out, sep=",")
  writeLines(paste(ATUT), out, sep=",")
  writeLines(paste(ATBIT), out, sep=",")
  writeLines(paste(ATST), out, sep=",")
  writeLines(paste(ATDOC), out, sep=",")
  writeLines(paste(ATPM), out, sep=",")
  writeLines(paste(ATAT), out, sep=",")
  writeLines(paste(ATPL), out, sep=",")
  writeLines(paste(ATTOTAL), out, sep=",")
  writeLines(paste(PRATE_MM), out, sep=",")
  writeLines(paste(PRATE_LS), out, sep=",")
  writeLines(paste(PRATE_PLAN), out, sep=",")
  writeLines(paste(PRATE_REQ), out, sep=",")
  writeLines(paste(PRATE_STP), out, sep=",")
  writeLines(paste(PRATE_REQINSP), out, sep=",")
  writeLines(paste(PRATE_HLD), out, sep=",")
  writeLines(paste(PRATE_ITP), out, sep=",")
  writeLines(paste(PRATE_HLDINSP), out, sep=",")
  writeLines(paste(PRATE_DLD), out, sep=",")
  writeLines(paste(PRATE_DLDR), out, sep=",")
  writeLines(paste(PRATE_TD), out, sep=",")
  writeLines(paste(PRATE_DLDINSP), out, sep=",")
  writeLines(paste(PRATE_CODE), out, sep=",")
  writeLines(paste(PRATE_CR), out, sep=",")
  writeLines(paste(PRATE_COMPILE), out, sep=",")
  writeLines(paste(PRATE_INSP), out, sep=",")
  writeLines(paste(PRATE_UT), out, sep=",")
  writeLines(paste(PRATE_BIT), out, sep=",")
  writeLines(paste(PRATE_ST), out, sep=",")
  writeLines(paste(PRATE_DOC), out, sep=",")
  writeLines(paste(PRATE_PM), out, sep=",")
  writeLines(paste(PRATE_AT), out, sep=",")
  writeLines(paste(PRATE_PL), out, sep=",")
  writeLines(paste(ARATE_MM), out, sep=",")
  writeLines(paste(ARATE_LS), out, sep=",")
  writeLines(paste(ARATE_PLAN), out, sep=",")
  writeLines(paste(ARATE_REQ), out, sep=",")
  writeLines(paste(ARATE_STP), out, sep=",")
  writeLines(paste(ARATE_REQINSP), out, sep=",")
  writeLines(paste(ARATE_HLD), out, sep=",")
  writeLines(paste(ARATE_ITP), out, sep=",")
  writeLines(paste(ARATE_HLDINSP), out, sep=",")
  writeLines(paste(ARATE_DLD), out, sep=",")
  writeLines(paste(ARATE_DLDR), out, sep=",")
  writeLines(paste(ARATE_TD), out, sep=",")
  writeLines(paste(ARATE_DLDINSP), out, sep=",")
  writeLines(paste(ARATE_CODE), out, sep=",")
  writeLines(paste(ARATE_CR), out, sep=",")
  writeLines(paste(ARATE_COMPILE), out, sep=",")
  writeLines(paste(ARATE_INSP), out, sep=",")
  writeLines(paste(ARATE_UT), out, sep=",")
  writeLines(paste(ARATE_BIT), out, sep=",")
  writeLines(paste(ARATE_ST), out, sep=",")
  writeLines(paste(ARATE_DOC), out, sep=",")
  writeLines(paste(ARATE_PM), out, sep=",")
  writeLines(paste(ARATE_AT), out, sep=",")
  writeLines(paste(ARATE_PL), out, sep=",")
  writeLines(paste(PT_PERCENT_MM), out, sep=",")
  writeLines(paste(PT_PERCENT_LS), out, sep=",")
  writeLines(paste(PT_PERCENT_PLAN), out, sep=",")
  writeLines(paste(PT_PERCENT_REQ), out, sep=",")
  writeLines(paste(PT_PERCENT_STP), out, sep=",")
  writeLines(paste(PT_PERCENT_REQINSP), out, sep=",")
  writeLines(paste(PT_PERCENT_HLD), out, sep=",")
  writeLines(paste(PT_PERCENT_ITP), out, sep=",")
  writeLines(paste(PT_PERCENT_HLDINSP), out, sep=",")
  writeLines(paste(PT_PERCENT_DLD), out, sep=",")
  writeLines(paste(PT_PERCENT_DLDR), out, sep=",")
  writeLines(paste(PT_PERCENT_TD), out, sep=",")
  writeLines(paste(PT_PERCENT_DLDINSP), out, sep=",")
  writeLines(paste(PT_PERCENT_CODE), out, sep=",")
  writeLines(paste(PT_PERCENT_CR), out, sep=",")
  writeLines(paste(PT_PERCENT_COMPILE), out, sep=",")
  writeLines(paste(PT_PERCENT_INSP), out, sep=",")
  writeLines(paste(PT_PERCENT_UT), out, sep=",")
  writeLines(paste(PT_PERCENT_BIT), out, sep=",")
  writeLines(paste(PT_PERCENT_ST), out, sep=",")
  writeLines(paste(PT_PERCENT_DOC), out, sep=",")
  writeLines(paste(PT_PERCENT_PM), out, sep=",")
  writeLines(paste(PT_PERCENT_AT), out, sep=",")
  writeLines(paste(PT_PERCENT_PL), out, sep=",")
  writeLines(paste(AT_PERCENT_MM), out, sep=",")
  writeLines(paste(AT_PERCENT_LS), out, sep=",")
  writeLines(paste(AT_PERCENT_PLAN), out, sep=",")
  writeLines(paste(AT_PERCENT_REQ), out, sep=",")
  writeLines(paste(AT_PERCENT_STP), out, sep=",")
  writeLines(paste(AT_PERCENT_REQINSP), out, sep=",")
  writeLines(paste(AT_PERCENT_HLD), out, sep=",")
  writeLines(paste(AT_PERCENT_ITP), out, sep=",")
  writeLines(paste(AT_PERCENT_HLDINSP), out, sep=",")
  writeLines(paste(AT_PERCENT_DLD), out, sep=",")
  writeLines(paste(AT_PERCENT_DLDR), out, sep=",")
  writeLines(paste(AT_PERCENT_TD), out, sep=",")
  writeLines(paste(AT_PERCENT_DLDINSP), out, sep=",")
  writeLines(paste(AT_PERCENT_CODE), out, sep=",")
  writeLines(paste(AT_PERCENT_CR), out, sep=",")
  writeLines(paste(AT_PERCENT_COMPILE), out, sep=",")
  writeLines(paste(AT_PERCENT_INSP), out, sep=",")
  writeLines(paste(AT_PERCENT_UT), out, sep=",")
  writeLines(paste(AT_PERCENT_BIT), out, sep=",")
  writeLines(paste(AT_PERCENT_ST), out, sep=",")
  writeLines(paste(AT_PERCENT_DOC), out, sep=",")
  writeLines(paste(AT_PERCENT_PM), out, sep=",")
  writeLines(paste(AT_PERCENT_AT), out, sep=",")
  writeLines(paste(AT_PERCENT_PL), out, sep=",")
  writeLines(paste(PDINJ_RATE_PLAN), out, sep=",")
  writeLines(paste(PDINJ_RATE_REQ), out, sep=",")
  writeLines(paste(PDINJ_RATE_STP), out, sep=",")
  writeLines(paste(PDINJ_RATE_REQINSP), out, sep=",")
  writeLines(paste(PDINJ_RATE_HLD), out, sep=",")
  writeLines(paste(PDINJ_RATE_ITP), out, sep=",")
  writeLines(paste(PDINJ_RATE_HLDINSP), out, sep=",")
  writeLines(paste(PDINJ_RATE_DLD), out, sep=",")
  writeLines(paste(PDINJ_RATE_DLDR), out, sep=",")
  writeLines(paste(PDINJ_RATE_TD), out, sep=",")
  writeLines(paste(PDINJ_RATE_DLDINSP), out, sep=",")
  writeLines(paste(PDINJ_RATE_CODE), out, sep=",")
  writeLines(paste(PDINJ_RATE_CR), out, sep=",")
  writeLines(paste(PDINJ_RATE_COMPILE), out, sep=",")
  writeLines(paste(PDINJ_RATE_INSP), out, sep=",")
  writeLines(paste(PDINJ_RATE_UT), out, sep=",")
  writeLines(paste(PDINJ_RATE_BIT), out, sep=",")
  writeLines(paste(PDINJ_RATE_ST), out, sep=",")
  writeLines(paste(PDINJ_RATE_AT), out, sep=",")
  writeLines(paste(PDINJ_RATE_PL), out, sep=",")
  writeLines(paste(PDINJ_RATE_TOTAL), out, sep=",")
  writeLines(paste(ADINJ_RATE_PLAN), out, sep=",")
  writeLines(paste(ADINJ_RATE_REQ), out, sep=",")
  writeLines(paste(ADINJ_RATE_STP), out, sep=",")
  writeLines(paste(ADINJ_RATE_REQINSP), out, sep=",")
  writeLines(paste(ADINJ_RATE_HLD), out, sep=",")
  writeLines(paste(ADINJ_RATE_ITP), out, sep=",")
  writeLines(paste(ADINJ_RATE_HLDINSP), out, sep=",")
  writeLines(paste(ADINJ_RATE_DLD), out, sep=",")
  writeLines(paste(ADINJ_RATE_DLDR), out, sep=",")
  writeLines(paste(ADINJ_RATE_TD), out, sep=",")
  writeLines(paste(ADINJ_RATE_DLDINSP), out, sep=",")
  writeLines(paste(ADINJ_RATE_CODE), out, sep=",")
  writeLines(paste(ADINJ_RATE_CR), out, sep=",")
  writeLines(paste(ADINJ_RATE_COMPILE), out, sep=",")
  writeLines(paste(ADINJ_RATE_INSP), out, sep=",")
  writeLines(paste(ADINJ_RATE_UT), out, sep=",")
  writeLines(paste(ADINJ_RATE_BIT), out, sep=",")
  writeLines(paste(ADINJ_RATE_ST), out, sep=",")
  writeLines(paste(ADINJ_RATE_AT), out, sep=",")
  writeLines(paste(ADINJ_RATE_PL), out, sep=",")
  writeLines(paste(ADINJ_RATE_TOTAL), out, sep=",")
  writeLines(paste(PDREM_RATE_PLAN), out, sep=",")
  writeLines(paste(PDREM_RATE_REQ), out, sep=",")
  writeLines(paste(PDREM_RATE_STP), out, sep=",")
  writeLines(paste(PDREM_RATE_REQINSP), out, sep=",")
  writeLines(paste(PDREM_RATE_HLD), out, sep=",")
  writeLines(paste(PDREM_RATE_ITP), out, sep=",")
  writeLines(paste(PDREM_RATE_HLDINSP), out, sep=",")
  writeLines(paste(PDREM_RATE_DLD), out, sep=",")
  writeLines(paste(PDREM_RATE_DLDR), out, sep=",")
  writeLines(paste(PDREM_RATE_TD), out, sep=",")
  writeLines(paste(PDREM_RATE_DLDINSP), out, sep=",")
  writeLines(paste(PDREM_RATE_CODE), out, sep=",")
  writeLines(paste(PDREM_RATE_CR), out, sep=",")
  writeLines(paste(PDREM_RATE_COMPILE), out, sep=",")
  writeLines(paste(PDREM_RATE_INSP), out, sep=",")
  writeLines(paste(PDREM_RATE_UT), out, sep=",")
  writeLines(paste(PDREM_RATE_BIT), out, sep=",")
  writeLines(paste(PDREM_RATE_ST), out, sep=",")
  writeLines(paste(PDREM_RATE_AT), out, sep=",")
  writeLines(paste(PDREM_RATE_PL), out, sep=",")
  writeLines(paste(PDREM_RATE_TOTAL), out, sep=",")
  writeLines(paste(ADREM_RATE_PLAN), out, sep=",")
  writeLines(paste(ADREM_RATE_REQ), out, sep=",")
  writeLines(paste(ADREM_RATE_STP), out, sep=",")
  writeLines(paste(ADREM_RATE_REQINSP), out, sep=",")
  writeLines(paste(ADREM_RATE_HLD), out, sep=",")
  writeLines(paste(ADREM_RATE_ITP), out, sep=",")
  writeLines(paste(ADREM_RATE_HLDINSP), out, sep=",")
  writeLines(paste(ADREM_RATE_DLD), out, sep=",")
  writeLines(paste(ADREM_RATE_DLDR), out, sep=",")
  writeLines(paste(ADREM_RATE_TD), out, sep=",")
  writeLines(paste(ADREM_RATE_DLDINSP), out, sep=",")
  writeLines(paste(ADREM_RATE_CODE), out, sep=",")
  writeLines(paste(ADREM_RATE_CR), out, sep=",")
  writeLines(paste(ADREM_RATE_COMPILE), out, sep=",")
  writeLines(paste(ADREM_RATE_INSP), out, sep=",")
  writeLines(paste(ADREM_RATE_UT), out, sep=",")
  writeLines(paste(ADREM_RATE_BIT), out, sep=",")
  writeLines(paste(ADREM_RATE_ST), out, sep=",")
  writeLines(paste(ADREM_RATE_AT), out, sep=",")
  writeLines(paste(ADREM_RATE_PL), out, sep=",")
  writeLines(paste(ADREM_RATE_TOTAL), out, sep=",")
  writeLines(paste(PDREM_YIELD_PLAN), out, sep=",")
  writeLines(paste(PDREM_YIELD_REQ), out, sep=",")
  writeLines(paste(PDREM_YIELD_STP), out, sep=",")
  writeLines(paste(PDREM_YIELD_REQINSP), out, sep=",")
  writeLines(paste(PDREM_YIELD_HLD), out, sep=",")
  writeLines(paste(PDREM_YIELD_ITP), out, sep=",")
  writeLines(paste(PDREM_YIELD_HLDINSP), out, sep=",")
  writeLines(paste(PDREM_YIELD_DLD), out, sep=",")
  writeLines(paste(PDREM_YIELD_DLDR), out, sep=",")
  writeLines(paste(PDREM_YIELD_TD), out, sep=",")
  writeLines(paste(PDREM_YIELD_DLDINSP), out, sep=",")
  writeLines(paste(PDREM_YIELD_CODE), out, sep=",")
  writeLines(paste(PDREM_YIELD_CR), out, sep=",")
  writeLines(paste(PDREM_YIELD_COMPILE), out, sep=",")
  writeLines(paste(PDREM_YIELD_INSP), out, sep=",")
  writeLines(paste(PDREM_YIELD_UT), out, sep=",")
  writeLines(paste(PDREM_YIELD_BIT), out, sep=",")
  writeLines(paste(PDREM_YIELD_ST), out, sep=",")
  writeLines(paste(PDREM_YIELD_AT), out, sep=",")
  writeLines(paste(PDREM_YIELD_PL), out, sep=",")
  writeLines(paste(ADREM_YIELD_PLAN), out, sep=",")
  writeLines(paste(ADREM_YIELD_REQ), out, sep=",")
  writeLines(paste(ADREM_YIELD_STP), out, sep=",")
  writeLines(paste(ADREM_YIELD_REQINSP), out, sep=",")
  writeLines(paste(ADREM_YIELD_HLD), out, sep=",")
  writeLines(paste(ADREM_YIELD_ITP), out, sep=",")
  writeLines(paste(ADREM_YIELD_HLDINSP), out, sep=",")
  writeLines(paste(ADREM_YIELD_DLD), out, sep=",")
  writeLines(paste(ADREM_YIELD_DLDR), out, sep=",")
  writeLines(paste(ADREM_YIELD_TD), out, sep=",")
  writeLines(paste(ADREM_YIELD_DLDINSP), out, sep=",")
  writeLines(paste(ADREM_YIELD_CODE), out, sep=",")
  writeLines(paste(ADREM_YIELD_CR), out, sep=",")
  writeLines(paste(ADREM_YIELD_COMPILE), out, sep=",")
  writeLines(paste(ADREM_YIELD_INSP), out, sep=",")
  writeLines(paste(ADREM_YIELD_UT), out, sep=",")
  writeLines(paste(ADREM_YIELD_BIT), out, sep=",")
  writeLines(paste(ADREM_YIELD_ST), out, sep=",")
  writeLines(paste(ADREM_YIELD_AT), out, sep=",")
  writeLines(paste(ADREM_YIELD_PL), out, sep=",")
  writeLines(paste(PREMRATE_DEFECT_RATE_UT), out, sep=",")
  writeLines(paste(PREMRATE_DEFECT_RATE_BIT), out, sep=",")
  writeLines(paste(PREMRATE_DEFECT_RATE_ST), out, sep=",")
  writeLines(paste(PREMRATE_DEFECT_RATE_AT), out, sep=",")
  writeLines(paste(PREMRATE_DEFECT_RATE_PL), out, sep=",")
  writeLines(paste(PZero_DEFECT_RATE_UT), out, sep=",")
  writeLines(paste(PZero_DEFECT_RATE_BIT), out, sep=",")
  writeLines(paste(PZero_DEFECT_RATE_ST), out, sep=",")
  writeLines(paste(PZero_DEFECT_RATE_AT), out, sep=",")
  writeLines(paste(PZero_DEFECT_RATE_PL), out, sep=",")
  writeLines(paste(AM_Size_Estimation_Accuracy), out, sep=",")
  writeLines(paste(Effort_Estimation_Accuracy), out, sep=",")
  writeLines(paste(Actual_Production_Rate), out, sep=",")
  writeLines(paste(TRREQINSP2REQ), out, sep=",")
  writeLines(paste(TRHLDINSP2HLD), out, sep=",")
  writeLines(paste(TRDLDINSP2DLD), out, sep=",")
  writeLines(paste(TRDLDR2DLD), out, sep=",")
  writeLines(paste(TRCODEINSP2CODE), out, sep=",")
  writeLines(paste(TRCR2CODE), out, sep=",")
  writeLines(paste(TRDESGN2CODE), out, sep=",")
  writeLines(paste(COQPct), out, sep=",")
  writeLines(paste(COQPctAppraisal), out, sep=",")
  writeLines(paste(COQPctFailure), out, sep=",")
  writeLines(paste(DDDLDR), out, sep=",")
  writeLines(paste(DDDLDINSP), out, sep=",")
  writeLines(paste(DDCR), out, sep=",")
  writeLines(paste(DDCOMPILE), out, sep=",")
  writeLines(paste(DDINSP), out, sep=",")
  writeLines(paste(DDUT), out, sep=",")
  writeLines(paste(DDBIT), out, sep=",")
  writeLines(paste(DDST), out, sep=",")
  writeLines(paste(DDTOTAL), out, sep=",")
  writeLines(paste(COAratio_size), out, sep=",")
  writeLines(paste(COFratio_size), out, sep=",")
  writeLines(paste(COQratio_size), out, sep=",")
  writeLines(paste(construction_effort), out, sep=",")
  writeLines(paste(total_effort), out, sep=",")
  writeLines(paste(produc_rate_const), out, sep=",") 
  writeLines(paste(produc_rate_total), out, sep=",")
  writeLines(paste(COAinDLDUT), out, sep=",")
  writeLines(paste(COFinDLDUT), out, sep=",")
  writeLines(paste(COQinDLDUT), out, sep=",")
  writeLines(paste(COAinDLDUTratio_size), out, sep=",")
  writeLines(paste(COFinDLDUTratio_size), out, sep=",")
  writeLines(paste(COQinDLDUTratio_size), out, sep=",")
  writeLines(paste(DEFFIXTUT), out, sep="\n")
}

#close file
close(out)