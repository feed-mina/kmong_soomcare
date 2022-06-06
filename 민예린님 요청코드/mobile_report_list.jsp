<jsp:directive.page contentType="text/html;charset=utf-8"/>
<jsp:directive.page import="java.time.LocalDate, java.time.format.DateTimeFormatter"/>
<%
/***********************************************************************************
* Copyright (C)RFLOGIX since 2010.08.24 (rflogix@rflogix.com)
************************************************************************************
* ● 프로젝트	: SOOM2
* ○ 파일명		: history_show.jsp
************************************************************************************/
%>
<jsp:directive.page import="com.bean.*, com.common.*, java.util.*, java.text.SimpleDateFormat"/>
<jsp:directive.include file="/view/common/page_constant.jsp"/>
<%
String Day_GreaterThan = LocalDate.now().minusMonths(1).format(DateTimeFormatter.ofPattern("yyyy-MM-dd")); // 1달전 날짜
String Day_Before = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd")); // 오늘 날짜
// 회원정보
UserBean UserBean_Param = new UserBean();
UserBean_Param.USER_NO = GF.getInt(request.getParameter("USER_NO"));
ArrayList<UserBean> arrUser = DBManager.findByObject(UserBean_Param);

System.out.println(arrUser.size());
// 공통
FeedHistoryBean FeedHistoryBean_Param = GF.convertRequestToObject(request, new FeedHistoryBean());
FeedHistoryBean_Param.REGISTER_DT().Before = GF.addTime_Day(FeedHistoryBean_Param.REGISTER_DT().Before, 1);
FeedHistoryBean_Param.ALIVE_FLAG = 1;
FeedHistoryBean_Param.Search_OrderBy = FeedHistoryBean_Param.DB_TABLE+".REGISTER_DT DESC";
// 증상
FeedHistoryBean_Param.CATEGORY().In = GC.FEED_HISTORY_COUGH +","+ GC.FEED_HISTORY_BREATH +","+ GC.FEED_HISTORY_ROARING +","+ GC.FEED_HISTORY_CHEST +","+ GC.FEED_HISTORY_ETC;
ArrayList<FeedHistoryBean> arrFeed_CAUSE = DBManager.findByObject(FeedHistoryBean_Param);
FeedHistoryBean_Param.CATEGORY().In = ""; // 초기화
String[] CauseCD; String CauseNMs = "";
// 복약
FeedHistoryBean_Param.CATEGORY = GC.FEED_HISTORY_MEDICINE;
ArrayList<FeedHistoryBean> arrFeed_MEDI = DBManager.findByObject(FeedHistoryBean_Param);
FeedHistoryBean_Param.CATEGORY = 0; // 초기화
// ACT
FeedHistoryBean_Param.CATEGORY = GC.FEED_HISTORY_ACT;
ArrayList<FeedHistoryBean> arrFeed_ACT = DBManager.findByObject(FeedHistoryBean_Param);
FeedHistoryBean_Param.CATEGORY = 0; // 초기화
// PEF
FeedHistoryBean_Param.CATEGORY = GC.FEED_HISTORY_PEF;
ArrayList<FeedHistoryBean> arrFeed_PEF = DBManager.findByObject(FeedHistoryBean_Param);
FeedHistoryBean_Param.CATEGORY = 0; // 초기화
// 미세먼지
FeedHistoryBean_Param.CATEGORY = GC.FEED_HISTORY_DUST;
ArrayList<FeedHistoryBean> arrFeed_DUST = DBManager.findByObject(FeedHistoryBean_Param);
FeedHistoryBean_Param.CATEGORY = 0; // 초기화
// 메모
FeedHistoryBean_Param.CATEGORY = GC.FEED_HISTORY_MEMO;
FeedHistoryBean_Param.clsImagesBean_JoinYN = 1;
ArrayList<FeedHistoryBean> arrFeed_MEMO = DBManager.findByObject(FeedHistoryBean_Param);
FeedHistoryBean_Param.CATEGORY = 0; // 초기화


%>
<!DOCTYPE html>
<html>
	<head>
		<%-- page head --%>
		<jsp:directive.include file="/view/common/page_head.jsp"/>
		
		<script src="/resources/js/history_summary.js<%= SITE_VER %>"></script>
		<link href="/resources/css/history_summary.css<%= SITE_VER %>" rel="stylesheet" type="text/css"/>
	</head>
	<style>
	@FONT-FACE{
		font-family:'notoSansKrMedium';
		src:url("/resources/fonts/NotoSansKR-Medium.otf")
	}
	</style>
	<body>
<!-- 	<div style="max-height:200px;twxt-align:center;width:100%;"><img style="max-height:200px;height:auto;width:100vw;" src="/resources/images/common/reportListBanner.png"></div> -->
	<div style="display:flex;max-height:200px;twxt-align:center;width:100%;"><img style="max-height:200px;height:auto;width:90vw;margin:auto" src="/resources/images/common/reportListBanner2.png"></div>
				
	
		<%-- page content --%>
		<div>
			<%-- 검색조건 --%>
				<%if (arrFeed_CAUSE.size() > 0 || arrFeed_MEDI.size() > 0) {
					//월 목록을 구하기 위한 프로세스 ex) 202001, 202002 ... 
					//최소/최대 날짜 구하기
					Date minDate = null;
					Date maxDate = null;
					for (int i=0;i<arrFeed_CAUSE.size();i++) {
						Date to = GF.stringToDate(arrFeed_CAUSE.get(i).CREATE_DT);
						if(to != null){
							if(minDate == null)	minDate = to;
							if(maxDate == null) maxDate = to;
							if(minDate.compareTo(to) > 0) minDate = to;
							if(maxDate.compareTo(to) < 0) maxDate = to;
						}
					}
			 		for (int i=0;i<arrFeed_MEDI.size();i++) {
						Date to = GF.stringToDate(arrFeed_MEDI.get(i).CREATE_DT);
						if(to != null){
							if(minDate == null)	minDate = to;
							if(maxDate == null) maxDate = to;
							if(minDate.compareTo(to) > 0) minDate = to;
							if(maxDate.compareTo(to) < 0) maxDate = to;
						}
					} 
			 		String minYYYYMM = ""+(minDate.getYear()+1900)+(minDate.getMonth()+1);
			 		String maxYYYYMM = ""+(maxDate.getYear()+1900)+(maxDate.getMonth()+1);
			 		Boolean compareFlag = true;
			 		String compareString = maxYYYYMM;
			 		String minCompareString = GF.decreaseMonth(minYYYYMM);
			 		%><div style="background-color: #d5d5d5;height:1px;width:100wh;margin-left:16px;margin-right:16px; margin-top: 20px;"></div><%
			 		while(compareFlag){
			 			if(minCompareString.equals(compareString)==false){
			 				System.out.println("nick = "+arrUser.get(0).NICKNAME);
			 				%>
			 				<div onclick="moveReport( <%="'"+arrUser.get(0).NICKNAME+"'"%>,<%=GF.dateStringToStringYYYYMM(compareString) %> );" style="width:auto;height:56px;margin-left:16px;margin-right:16px;cursor:pointer;line-height: 35px;color: blue;">
			 				<a style="position: absolute;top: 14px;color: #000000;font-size: 14px;font-family:notoSansKrMedium;"><%=GF.dateStringToStringYYYYMMKO(compareString) %>월 천식보고서</a>
			 				<img style="position: absolute;top: 14px;right:4px;width:24px;height:24px;" src="/resources/images/common/rightArrowBlack.png"></img>
			 				</div>
			 				<div style="background-color: #d5d5d5;height:1px;width:100wh;margin-left:16px;margin-right:16px;"></div>
			 				<%
			 				compareString = GF.decreaseMonth(compareString);
			 			}
			 			if(minCompareString.equals(compareString)){
			 				compareFlag = false;
			 			}
			 		}
			 		%>			
			 	<%} else { %>
					<div class="no_feed">기록이 없습니다</div>
				<% } %>
		</div>
		<script>
			function moveReport(nickname, YYYYMM) {
				location.href = "../report?NICKNAME="+nickname+"&MONTH="+YYYYMM, "_blank";
			}
		</script>
	</body>
</html>