<jsp:directive.page contentType="text/html;charset=utf-8"/>
<%
/***********************************************************************************
* Copyright PLAYBENCH LTD,. EUIBO SIM
************************************************************************************
* ● 프로젝트	: SOOM2
* ○ 파일명		: webView/report.jsp
************************************************************************************/
%>
<jsp:directive.page import="com.bean.*, com.common.*, java.util.*, java.text.SimpleDateFormat"/>
<jsp:directive.include file="/controller/MedicineManager.jsp"/>
<%
	

	SimpleDateFormat format1 = new SimpleDateFormat ( "yyyyMM");
	Date time = new Date();
	String time1 = format1.format(time);
	//날짜 세팅
	Date searchStartMonth = GF.stringToDateForMonth(GF.getString(time1)+"01");
	String Day_GreaterThan = GF.dateToDateStringHyphen(searchStartMonth);
	
	Date searchEndMonth = GF.stringToDateForMonth(GF.increaseMonth( GF.getString(time1))+"01");
	String Day_Before = GF.dateToDateStringHyphen(searchEndMonth);
	
	//말일 구하기
	Calendar cal = Calendar.getInstance();
	cal.setTime(searchStartMonth);
	int lastDay = cal.getActualMaximum(Calendar.DAY_OF_MONTH);
	
	
	UserBean UserBean_Param = new UserBean();
	UserBean_Param.NICKNAME = GF.getString(request.getParameter("NICKNAME"));
	ArrayList<UserBean> arrUser = DBManager.findByObject(UserBean_Param);
	
	
	String gender = "남";
	String definiteDiagnosis = "확진";

	
	int userNo = arrUser.get(0).USER_NO;
	
	// 공통
	FeedHistoryBean FeedHistoryBean_Param = GF.convertRequestToObject(request, new FeedHistoryBean());
	FeedHistoryBean_Param.REGISTER_DT().GreaterThan = Day_GreaterThan;
	FeedHistoryBean_Param.REGISTER_DT().Before = Day_Before;
	FeedHistoryBean_Param.USER_NO = userNo;
	FeedHistoryBean_Param.NICKNAME = "";
	FeedHistoryBean_Param.ALIVE_FLAG = 1;
	FeedHistoryBean_Param.Search_OrderBy = FeedHistoryBean_Param.DB_TABLE+".REGISTER_DT DESC";


	//복용중인 약
	FeedHistoryBean medicineHistoryBean_Param = new FeedHistoryBean();
	medicineHistoryBean_Param.ALIVE_FLAG = 1;
	medicineHistoryBean_Param.USER_NO = userNo;
	medicineHistoryBean_Param.clsMedicineBean_JoinYN = 1;
	medicineHistoryBean_Param.clsMedicineHistoryBean_JoinYN = 1;
	MedicineManager clsMedicineManager = new MedicineManager();
	String startDt = time1+"01";
	String lastDt = time1+lastDay;
	ArrayList<FeedHistoryBean> arrMedicineHistory = clsMedicineManager.findByMedicineHistoryListForReport(medicineHistoryBean_Param, startDt , lastDt);
	// 복약은 최대 12개까지만 표현한다.
	ArrayList<FeedHistoryBean> arrMedicineHistoryNew = new ArrayList<FeedHistoryBean>();
	for(int i=0;i<arrMedicineHistory.size();i++){
		if(i<12){
			arrMedicineHistoryNew.add(arrMedicineHistory.get(i));
		}
	}
	
	//약 카드 정보 만들기 약이름, 용량, 빈도수, 일반복용 횟수
	ArrayList<String> mediStartDt = new ArrayList<String>();
	ArrayList<String> mediEndDt = new ArrayList<String>();
	ArrayList<String> mediNameArr = new ArrayList<String>();
	ArrayList<String> mediUnitArr = new ArrayList<String>();
	ArrayList<String> mediVolumeArr = new ArrayList<String>();
	ArrayList<Integer> mediFrqArr = new ArrayList<Integer>();
	ArrayList<Integer> mediEmgArr = new ArrayList<Integer>();
	ArrayList<Double> mediGoalCount = new ArrayList<Double>();
	ArrayList<Integer> mediNoArr = new ArrayList<Integer>();
	
	SimpleDateFormat df = new SimpleDateFormat("yyyyMMdd");
	for(int i=0;i<arrMedicineHistoryNew.size();i++){
		if(df.parse(arrMedicineHistoryNew.get(i).START_DT).compareTo(df.parse(GF.getString("202005")+"01")) < 0){
			if(df.parse(arrMedicineHistoryNew.get(i).END_DT).compareTo(df.parse(GF.getString("202005")+lastDay)) > 0){
				//범위 밖인 경우(예전부터 다음달 이후까지 계속 복약해야 하는 경우 )
				mediGoalCount.add((double)lastDay);
			}else{
				//이전부터 복용했지만 이번달까지 복용하는 경우
				mediGoalCount.add((double) GF.stringToDateForMonth(arrMedicineHistoryNew.get(i).END_DT).getDate());
			}
		}else{
			if(df.parse(arrMedicineHistoryNew.get(i).END_DT).compareTo(df.parse(GF.getString("202005")+lastDay)) > 0){
				//범위 밖인 경우(이번달부터 복용해서 다음달 이후까지 계속 복약해야 하는 경우 )
				mediGoalCount.add((double) (lastDay - GF.stringToDateForMonth(arrMedicineHistoryNew.get(i).START_DT).getDate()));
			}else{
				//이번달에 복용해서 이번달까지 복용하는 경우 
				mediGoalCount.add((double) (GF.stringToDateForMonth(arrMedicineHistoryNew.get(i).END_DT).getDate() - GF.stringToDateForMonth(arrMedicineHistoryNew.get(i).START_DT).getDay()));
			}
		}
		mediNameArr.add(arrMedicineHistoryNew.get(i).clsMedicineBean.KO);
		mediUnitArr.add(arrMedicineHistoryNew.get(i).UNIT);
		
		if(GF.isEmptyNull(arrMedicineHistoryNew.get(i).clsMedicineHistoryBean.CREATE_DT)){
			mediVolumeArr.add(arrMedicineHistoryNew.get(i).clsMedicineHistoryBean.VOLUME);
			mediFrqArr.add(arrMedicineHistoryNew.get(i).clsMedicineHistoryBean.FREQUENCY);
		}else{
			mediVolumeArr.add(arrMedicineHistoryNew.get(i).VOLUME);
			mediFrqArr.add(arrMedicineHistoryNew.get(i).FREQUENCY);
		}
		mediNoArr.add(arrMedicineHistoryNew.get(i).MEDICINE_NO);
		mediEmgArr.add(arrMedicineHistoryNew.get(i).EMERGENCY_FLAG);
	}
	//복용한 약

	// 복약 - 약 종류별 총 먹은 개수 구하기(응급약 제외)

	
	
	//다니는 병원
	HospitalBean HospitalBean_Param = new HospitalBean();
	HospitalBean_Param.USER_NO = userNo;
	ArrayList<HospitalBean> arrHospitalBean = DBManager.findByObject(HospitalBean_Param);
	String hosName = "";
	String docName = "";
	String department = "";
	if(arrHospitalBean.size()>0){
		if(arrHospitalBean.get(0).NAME.equals("")==false){
			hosName = arrHospitalBean.get(0).NAME;
		}
		if(arrHospitalBean.get(0).DOCTOR.equals("")==false){
			docName = arrHospitalBean.get(0).DOCTOR;
		}
		if(arrHospitalBean.get(0).DEPARTMENT.equals("")==false){
			department = "("+arrHospitalBean.get(0).DEPARTMENT+")";
		}
	}
	
	
	// 증상
	FeedHistoryBean_Param.CATEGORY().In = GC.FEED_HISTORY_COUGH +","+ GC.FEED_HISTORY_BREATH +","+ GC.FEED_HISTORY_ROARING +","+ GC.FEED_HISTORY_CHEST+","+ GC.FEED_HISTORY_PHLEGM +","+ GC.FEED_HISTORY_NO_SYMPTOM +","+ GC.FEED_HISTORY_ETC;
	ArrayList<FeedHistoryBean> arrFeed_CAUSE = DBManager.findByObject(FeedHistoryBean_Param);
	FeedHistoryBean_Param.CATEGORY().In = ""; // 초기화
	String[] CauseCD; String CauseNMs = "";
	
	
	ArrayList<FeedHistoryBean> arrFeedCause0to6 = new ArrayList<FeedHistoryBean>();		// 밤
	ArrayList<FeedHistoryBean> arrFeedCause6to12 = new ArrayList<FeedHistoryBean>();	// 아침
	ArrayList<FeedHistoryBean> arrFeedCause12to18 = new ArrayList<FeedHistoryBean>();	// 점심
	ArrayList<FeedHistoryBean> arrFeedCause18to24 = new ArrayList<FeedHistoryBean>();	// 저녁
	
	int isSickDayCnt = 0, nightSickCnt = 5, coughCnt = (int)( Math.random() * 20 + 1), breathCnt = (int)( Math.random() * 20 + 1), roaringCnt = (int)( Math.random() * 20 + 1), chestCnt = (int)( Math.random() * 20 + 1), etcCnt = (int)( Math.random() * 20 + 1),phlegmCnt = (int)( Math.random() * 20 + 1),noSymptomCnt = (int)( Math.random() * 20 + 1), causeCnt=10;
	ArrayList<String> nightDateArr = new ArrayList<String>();
	ArrayList<String> causeArr = new ArrayList<String>();
	int arrCauseSize = arrFeed_CAUSE.size();
	String coughBuff = "";
	String breathBuff = "";
	String roaringBuff = "";
	String chestBuff = "";
	String etcBuff = "";
	String phlegmBuff = "";
	String noSymptomBuff = "";

	int totalCoughCnt = coughCnt, totalBreathCnt = breathCnt, totalRoaringCnt = roaringCnt, totalChestCnt = chestCnt, totalEtcCnt = etcCnt, totalPhlegmCnt = phlegmCnt, totalNoSymptomCnt = noSymptomCnt;

	for(int i=0;i<arrCauseSize;i++){
		//증상없음 필터링 할 부분
			if(arrFeed_CAUSE.get(i).CATEGORY != 40){
				if( causeArr.contains((GF.stringToDate(arrFeed_CAUSE.get(i).REGISTER_DT).getDate()+""))==false ){
					String temp = GF.stringToDate(arrFeed_CAUSE.get(i).REGISTER_DT).getDate()+"";
					causeArr.add(temp);
				}
			}
		if( GF.stringToDate(arrFeed_CAUSE.get(i).REGISTER_DT).getHours() > 21 || GF.stringToDate(arrFeed_CAUSE.get(i).REGISTER_DT).getHours() < 6 ){
			//야간증상 중복제거 하지 않았음(날짜별로 필요)
			if( nightDateArr.contains((GF.stringToDate(arrFeed_CAUSE.get(i).REGISTER_DT).getDate()+""))==false ){
				String temp = GF.stringToDate(arrFeed_CAUSE.get(i).REGISTER_DT).getDate()+"";
				nightDateArr.add(temp);
			}
			
		}
		if(GF.stringToDate(arrFeed_CAUSE.get(i).REGISTER_DT).getHours() < 6){
			arrFeedCause0to6.add(arrFeed_CAUSE.get(i));
		}else if(GF.stringToDate(arrFeed_CAUSE.get(i).REGISTER_DT).getHours() < 12){
			arrFeedCause6to12.add(arrFeed_CAUSE.get(i));
		}else if(GF.stringToDate(arrFeed_CAUSE.get(i).REGISTER_DT).getHours() < 18){
			arrFeedCause12to18.add(arrFeed_CAUSE.get(i));
		}else if(GF.stringToDate(arrFeed_CAUSE.get(i).REGISTER_DT).getHours() < 24){
			arrFeedCause18to24.add(arrFeed_CAUSE.get(i));
		}
		
	}
	for(int i=0;i<arrFeedCause6to12.size();i++){//아침인 경우
		if(arrFeedCause6to12.get(i).CATEGORY==GC.FEED_HISTORY_COUGH){
			coughCnt++;
			totalCoughCnt++;
		}
		if(arrFeedCause6to12.get(i).CATEGORY==GC.FEED_HISTORY_BREATH){
			breathCnt++;
			totalBreathCnt++;
		}
		if(arrFeedCause6to12.get(i).CATEGORY==GC.FEED_HISTORY_ROARING){
			roaringCnt++;
			totalRoaringCnt++;
		}
		if(arrFeedCause6to12.get(i).CATEGORY==GC.FEED_HISTORY_CHEST){
			chestCnt++;
			totalChestCnt++;
		}
		if(arrFeedCause6to12.get(i).CATEGORY==GC.FEED_HISTORY_ETC){
			etcCnt++;
			totalEtcCnt++;
		}
		if(arrFeedCause6to12.get(i).CATEGORY==GC.FEED_HISTORY_PHLEGM){
			phlegmCnt++;
			totalPhlegmCnt++;
		}
		if(arrFeedCause6to12.get(i).CATEGORY==GC.FEED_HISTORY_ETC){
			noSymptomCnt++;
			totalNoSymptomCnt++;
		}
	}
	coughBuff+=coughCnt+",";
	breathBuff+=breathCnt+",";
	roaringBuff+=roaringCnt+",";
	chestBuff+=chestCnt+",";
	etcBuff+=etcCnt+",";
	phlegmBuff+=phlegmCnt+",";
	noSymptomBuff+=noSymptomCnt+",";
	coughCnt = (int)( Math.random() * 20 + 1); breathCnt = (int)( Math.random() * 20 + 1); roaringCnt = (int)( Math.random() * 20 + 1); chestCnt = (int)( Math.random() * 20 + 1); etcCnt = (int)( Math.random() * 20 + 1); phlegmCnt = (int)( Math.random() * 20 + 1); noSymptomCnt = (int)( Math.random() * 20 + 1);
	totalCoughCnt += coughCnt;
	totalBreathCnt += breathCnt;
	totalChestCnt += roaringCnt;
	totalEtcCnt += chestCnt;
	totalPhlegmCnt += etcCnt;
	totalNoSymptomCnt += phlegmCnt;
	for(int i=0;i<arrFeedCause12to18.size();i++){//점심인 경우
		if(arrFeedCause12to18.get(i).CATEGORY==GC.FEED_HISTORY_COUGH){
			coughCnt++;
			totalCoughCnt++;
		}
		if(arrFeedCause12to18.get(i).CATEGORY==GC.FEED_HISTORY_BREATH){
			breathCnt++;
			totalBreathCnt++;
		}
		if(arrFeedCause12to18.get(i).CATEGORY==GC.FEED_HISTORY_ROARING){
			roaringCnt++;
			totalRoaringCnt++;
		}
		if(arrFeedCause12to18.get(i).CATEGORY==GC.FEED_HISTORY_CHEST){
			chestCnt++;
			totalChestCnt++;
		}
		if(arrFeedCause12to18.get(i).CATEGORY==GC.FEED_HISTORY_ETC){
			etcCnt++;
			totalEtcCnt++;
		}
		if(arrFeedCause12to18.get(i).CATEGORY==GC.FEED_HISTORY_PHLEGM){
			phlegmCnt++;
			totalPhlegmCnt++;
		}
		if(arrFeedCause12to18.get(i).CATEGORY==GC.FEED_HISTORY_NO_SYMPTOM){
			noSymptomCnt++;
			totalNoSymptomCnt++;
		}
	}
	coughBuff+=coughCnt+",";
	breathBuff+=breathCnt+",";
	roaringBuff+=roaringCnt+",";
	chestBuff+=chestCnt+",";
	etcBuff+=etcCnt+",";
	phlegmBuff+=phlegmCnt+",";
	noSymptomBuff+=noSymptomCnt+",";
	coughCnt = (int)( Math.random() * 20 + 1); breathCnt = (int)( Math.random() * 20 + 1); roaringCnt = (int)( Math.random() * 20 + 1); chestCnt = (int)( Math.random() * 20 + 1); etcCnt = (int)( Math.random() * 20 + 1); phlegmCnt = (int)( Math.random() * 20 + 1); noSymptomCnt = (int)( Math.random() * 20 + 1);
	totalCoughCnt += coughCnt;
	totalBreathCnt += breathCnt;
	totalChestCnt += roaringCnt;
	totalEtcCnt += chestCnt;
	totalPhlegmCnt += etcCnt;
	totalNoSymptomCnt += phlegmCnt;
	for(int i=0;i<arrFeedCause18to24.size();i++){//저녁인 경우
		if(arrFeedCause18to24.get(i).CATEGORY==GC.FEED_HISTORY_COUGH){
			coughCnt++;
			totalCoughCnt++;
		}
		if(arrFeedCause18to24.get(i).CATEGORY==GC.FEED_HISTORY_BREATH){
			breathCnt++;
			totalBreathCnt++;
		}
		if(arrFeedCause18to24.get(i).CATEGORY==GC.FEED_HISTORY_ROARING){
			roaringCnt++;
			totalRoaringCnt++;
		}
		if(arrFeedCause18to24.get(i).CATEGORY==GC.FEED_HISTORY_CHEST){
			chestCnt++;
			totalChestCnt++;
		}
		if(arrFeedCause18to24.get(i).CATEGORY==GC.FEED_HISTORY_ETC){
			etcCnt++;
			totalEtcCnt++;
		}
		if(arrFeedCause18to24.get(i).CATEGORY==GC.FEED_HISTORY_PHLEGM){
			phlegmCnt++;
			totalPhlegmCnt++;
		}
		if(arrFeedCause18to24.get(i).CATEGORY==GC.FEED_HISTORY_NO_SYMPTOM){
			noSymptomCnt++;
			totalNoSymptomCnt++;
		}
	}
	coughBuff+=coughCnt+",";
	breathBuff+=breathCnt+",";
	roaringBuff+=roaringCnt+",";
	chestBuff+=chestCnt+",";
	etcBuff+=etcCnt+",";
	phlegmBuff+=phlegmCnt+",";
	noSymptomBuff+=noSymptomCnt+",";
	coughCnt = (int)( Math.random() * 20 + 1); breathCnt = (int)( Math.random() * 20 + 1); roaringCnt = (int)( Math.random() * 20 + 1); chestCnt = (int)( Math.random() * 20 + 1); etcCnt = (int)( Math.random() * 20 + 1); phlegmCnt = (int)( Math.random() * 20 + 1); noSymptomCnt = (int)( Math.random() * 20 + 1);
	totalCoughCnt += coughCnt;
	totalBreathCnt += breathCnt;
	totalChestCnt += roaringCnt;
	totalEtcCnt += chestCnt;
	totalPhlegmCnt += etcCnt;
	totalNoSymptomCnt += phlegmCnt;
	for(int i=0;i<arrFeedCause0to6.size();i++){//밤인 경우 
		if(arrFeedCause0to6.get(i).CATEGORY==GC.FEED_HISTORY_COUGH){
			coughCnt++;
			totalCoughCnt++;
		}
		if(arrFeedCause0to6.get(i).CATEGORY==GC.FEED_HISTORY_BREATH){
			breathCnt++;
			totalBreathCnt++;
		}
		if(arrFeedCause0to6.get(i).CATEGORY==GC.FEED_HISTORY_ROARING){
			roaringCnt++;
			totalRoaringCnt++;
		}
		if(arrFeedCause0to6.get(i).CATEGORY==GC.FEED_HISTORY_CHEST){
			chestCnt++;
			totalChestCnt++;
		}
		if(arrFeedCause0to6.get(i).CATEGORY==GC.FEED_HISTORY_ETC){
			etcCnt++;
			totalEtcCnt++;
		}
		if(arrFeedCause0to6.get(i).CATEGORY==GC.FEED_HISTORY_PHLEGM){
			phlegmCnt++;
			totalPhlegmCnt++;
		}
		if(arrFeedCause0to6.get(i).CATEGORY==GC.FEED_HISTORY_NO_SYMPTOM){
			noSymptomCnt++;
			totalNoSymptomCnt++;
		}
	}
	coughBuff+=coughCnt+",";
	breathBuff+=breathCnt+",";
	roaringBuff+=roaringCnt+",";
	chestBuff+=chestCnt+",";
	etcBuff+=etcCnt+",";
	phlegmBuff+=phlegmCnt+",";
	noSymptomBuff+=noSymptomCnt+",";
	coughCnt = 0; breathCnt = 0; roaringCnt = 0; chestCnt = 0; etcCnt = 0; phlegmCnt = 0; noSymptomCnt = 0;
	
	
	// 복약
	FeedHistoryBean_Param.CATEGORY = GC.FEED_HISTORY_MEDICINE;
	ArrayList<FeedHistoryBean> arrFeed_MEDI = DBManager.findByObject(FeedHistoryBean_Param);
	FeedHistoryBean_Param.CATEGORY = 0; // 초기화
	int totalEmergencyMedi = 10;
	int totalMedi = 0;
	int arrMediSize = arrFeed_MEDI.size();
	

	// ACT
	FeedHistoryBean_Param.CATEGORY = GC.FEED_HISTORY_ACT;
	ArrayList<FeedHistoryBean> arrFeed_ACT = DBManager.findByObject(FeedHistoryBean_Param);
	FeedHistoryBean_Param.CATEGORY = 0; // 초기화
	
	int actSum = 0, actAvg = 0, lastAct=18;
	String actRs = ""+lastAct+"점/25점";
	for(int i=0;i<arrFeed_ACT.size();i++){
		//actSum += arrFeed_ACT.get(i).ACT_SCORE;
		lastAct = arrFeed_ACT.get(i).ACT_SCORE;
	}
	// PEF
	FeedHistoryBean_Param.CATEGORY = GC.FEED_HISTORY_PEF;
// 	ArrayList<FeedHistoryBean> arrFeed_PEF = DBManager.findByObject(FeedHistoryBean_Param);
	FeedHistoryBean_Param.CATEGORY = 0; // 초기화
	int minPEF=9999,maxPEF=-1, axisMinPEFRS=0, axisMaxPEFRS = 0, yAxisCnt = 0;
	ArrayList<Integer> arrFeed_PEF = new ArrayList<>();
	ArrayList<String> arrFeed_reg = new ArrayList<>();
	ArrayList<Integer> arrFeed_flag = new ArrayList<>();
	double yAxisHeight = 0, avg = 0;
	
	for(int i = 0; i < lastDay; i++) {
		double dValue = Math.random();
		int iValue = (int)(dValue * 300 + 400);
		
		arrFeed_PEF.add(i, iValue);
	}
	
	for(int i = 0; i < lastDay; i++) {
		for(int j = 0; j < 2; j++){
			double dValue = Math.random();
			int hour = (int)(dValue * 24);
			dValue = Math.random();
			int min = (int)(dValue * 60);
			dValue = Math.random();
			int se = (int)(dValue * 60);
			String day = "2020-05-" + GF.getDay(i+1) + " " + hour + ":"+ min + ":"+ se;
			arrFeed_reg.add(i, day);
		}
	}
	
	for(int i = 0; i < lastDay; i++) {
		double dValue = Math.random();
		int iValue = (int)(dValue * 2);
		
		arrFeed_flag.add(i, iValue);
	}

	String minPEFRS = "No Data.";
	String maxPEFRS = "No Data.";
	for(int i=0;i<arrFeed_PEF.size();i++){
		if(minPEF > arrFeed_PEF.get(i)){
			minPEF = arrFeed_PEF.get(i);
		}
		if(maxPEF < arrFeed_PEF.get(i)){
			maxPEF = arrFeed_PEF.get(i);
		}
	}
	if(minPEF!=9999){
		minPEFRS = minPEF+" (L/m)";
	}
	if(maxPEF!=-1){
		maxPEFRS = maxPEF+" (L/m)";
	}
	if(minPEF!=9999){
		if(maxPEF == minPEF){
			axisMinPEFRS = ((minPEF/100) - 1)*100;
		}else{
			axisMinPEFRS = ((minPEF/100))*100;
		}
		axisMaxPEFRS = ((maxPEF/100)+1)*100;
		avg = ((axisMaxPEFRS + axisMinPEFRS)/2);
		yAxisCnt = (axisMaxPEFRS/100 - axisMinPEFRS/100)+1;
		if(minPEF <100){
			yAxisCnt--;
		}
		yAxisHeight = 200/yAxisCnt;
	}
// 	int testHeight=800;
%>
<!DOCTYPE html>
<html>
<head>
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<!-- google charts and chart js -->
   	<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
   	<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.8.0/Chart.bundle.min.js"></script>
	<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.8.0/Chart.min.js"></script>
	<!-- Thumb Nail -->
	<!-- Facebook Meta Tags / 페이스북 오픈 그래프 -->
<!-- 	<meta property="og:url" content="http://soomcare.com"> -->
	<meta property="og:type" content="website">
	<meta property="og:title" content="대한민국 1등 천식관리어플 숨케어">
	<meta property="og:description" content="<%=searchStartMonth.getMonth()+1 %>월 종합보고서">
	<meta property="og:image" content="http://soomcare.com/resources/images/common/thumbnail_image.png">
	
	<!-- Twitter Meta Tags / 트위터 -->
	<meta name="twitter:card" content="summary_large_image">
	<meta name="twitter:title" content="대한민국 1등 천식관리어플 숨케어">
	<meta name="twitter:description" content="<%=searchStartMonth.getMonth()+1 %>월 종합보고서">
	<meta name="twitter:image" content="http://soomcare.com//resources/images/common/thumbnail_image.png">
	
	<!-- Google / Search Engine Tags / 구글 검색 엔진 -->
	<meta itemprop="name" content="대한민국 1등 천식관리어플 숨케어">
	<meta itemprop="description" content="<%=searchStartMonth.getMonth()+1 %>월 종합보고서">
	<meta itemprop="image" content="http://soomcare.com//resources/images/common/thumbnail_image.png">
</head>
<style>
@import url(//fonts.googleapis.com/earlyaccess/notosanskr.css);
@media print {
	div {-webkit-print-color-adjust:exact;}
}
/* 모바일 수평 스크롤 금지 */
body {
overflow: hidden;
width: 100%;
-webkit-box-sizing: border-box;
-moz-box-sizing: border-box;
box-sizing: border-box;
}
@page {
  size: auto;
  margin: 0;  /* this affects the margin in the printer settings */
}

@media screen and (min-width: 800px) {
	body { color: #343434; background: #2A3F54; font-family: "Helvetica Neue",Roboto,Arial,"Droid Sans",sans-serif; font-size: 13px;font-weight: 400;line-height: 1.471; background-color: #d0d0d0;-webkit-print-color-adjust: exact;overflow: auto;}
	.background-wrap { background-color:#FFFFFF; margin: 0 auto; width: 1080px; height:3076px;  }
	.title-wrap {display:block;float:left;width:100%; height:100px; position: relative;min-height: 1px;float: left; }
	.sub-title-wrap { height:5%; }
	.medicine-content-box {  display: block;float:left; width: 342px;height: 144px;margin: 0px 3px 6px 9px;border-radius: 4px;border: solid 1px #acacac;background-color: #ffffff; }
}
@media screen and (max-width: 768px) {
  html, body {max-width: 100%;overflow-x: hidden;margin: 0px; padding: 0px;}
  .background-wrap {background-color:white; display:block;width:100% !important;}
  .page-1 { background-color:#d9d9d9 !important;height:auto !important;width: 100% !important; }
  .page-back-1 { display:none !important; }
  .img-logo1 { display:inline-block !important; position:unset !important; margin-left: 4% !important;height:auto !important;}
  .title-logo-text-area { display:inline-block !important; position:unset !important; width:247px !important; float: unset !important;}
  .title-info-user-info-title1 { display:block !important; position:unset !important; margin-left: 4% !important;font-size:24px !important; }
  
  .title-info-user-u1 { margin-left: 4% !important; width:100% !important; top:135px  !important; position:unset !important;line-height: 30px; }
  .title-info-user-i1 { margin-left: 4% !important; width:100% !important; top:160px  !important; position:unset !important;line-height: 30px; }
  .title-info-user-h1 { margin-left: 4% !important; width:100% !important; top:185px  !important; position:unset !important;line-height: 30px; }
  .title-info-user-d1 { margin-left: 4% !important; width:100% !important; top:210px  !important; position:unset !important;line-height: 30px; }
  .title-info-user-info-line1 { display:none !important;width:100% !important; height:20px !important;position:unset !important; }
  .title-point { display:none !important; }
  .title-info { margin-left: 4% !important;position:unset !important; font-size:16px !important;font-weight: bold;float:left !important; margin-top: 20px;font-size:24px !important;}
  .title-medicine-comment { margin-top: 0px !important;margin-left: 4% !important;position:unset !important; font-size:14px !important;width:90%;display: inline-block; }
  .title-medi-legend1 { margin-top: 20px;position:unset !important; float: right !important; margin-right: 4%; }
  .title-medi-legend-rect1 { display:block !important;margin-top: 20px;position:unset !important; float: right !important; width:18px !important;height:18px !important; }
  .title-medi-legend2 { margin-top: 20px;position:unset !important; float: right !important; margin-right: 10px; }
  .title-medi-legend-rect2 { display:block !important;margin-top: 20px;position:unset !important; float: right !important; width:18px !important;height:18px !important; }
  
  
  .overall-medi1 { margin-left: 4% !important; margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.1); }
  .overall-medi2 { margin-left: 4% !important;margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.1); }
  .overall-medi3 { margin-left: 4% !important;margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.1); }
  
  .overall-medi-title1 { position:relative !important; display: inline-block;  }
  .overall-medi-title2 { position:relative !important; display: inline-block; }
  .overall-medi-title3 { position:relative !important; display: inline-block; }
  
  .overall-medi-val3 { position:relative !important; display: inline-block;text-align: right; width:56% !important; }
  .overall-medi-val2 { position:relative !important; display: inline-block;text-align: right; width:56% !important; }
  .overall-medi-val1 { position:relative !important; display: inline-block;text-align: right; width:46% !important; }
  .mediList1 { display:none !important; }
  .mediList2 { display:none !important; }
  .mediList3 { display:none !important; }
  .mediList4 { display:none !important; }
  .mediList5 { display:none !important; }
  .mediList6 { display:none !important; }
  .mediList7 { display:none !important; }
  .mediList8 { display:none !important; }
  .mediList9 { display:none !important; }
  .mediList10 { display:none !important; }
  .mediList11 { display:none !important; }
  .mediList12 { display:none !important; }
  .medi-card0 { margin-left:4% ;margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.2);border: none !important; }
  .medi-card1 { margin-left:4% ;margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.2);border: none !important; }
  .medi-card2 { margin-left:4% ;margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.2);border: none !important; }
  .medi-card3 { margin-left:4% ;margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.2);border: none !important; }
  .medi-card4 { margin-left:4% ;margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.2);border: none !important; }
  .medi-card5 { margin-left:4% ;margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.2);border: none !important; }
  .medi-card6 { margin-left:4% ;margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.2);border: none !important; }
  .medi-card7 { margin-left:4% ;margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.2);border: none !important; }
  .medi-card8 { margin-left:4% ;margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.2);border: none !important; }
  .medi-card9 { margin-left:4% ;margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.2);border: none !important; }
  .medi-card10 { margin-left:4% ;margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.2);border: none !important; }
  .medi-card11 { margin-left:4% ;margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.2);border: none !important; }
  .medi-card-line { position:relative !important; left:2% !important;width:96% !important; top:10px !important;}
  .medi-card-name { position:relative !important; top: 5px !important; }
  .medi-card-persent { position:relative !important; left:78% !important;top: -31% !important; }
  .medi-card-t1 {  margin-left:4% ;margin-top: 20px;width:70% !important;position:unset !important; }
  .medi-card-t2 {  margin-left:4% ;margin-top: 10px;width:70% !important;position:unset !important; }
  .medi-card-t3 {  margin-left:4% ;margin-top: 10px;width:70% !important;position:unset !important; }
  .card-cause1 { margin-left: 4% !important; margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.1); }
  .card-cause2 { margin-left: 4% !important; margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.1); }
  .card-cause3 { margin-left: 4% !important; margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.1); }
  .card-cause-title { position:relative !important; display: inline-block; }
  .card-cause-val { position:relative !important; display: inline-block;text-align: right; width:58% !important; }
  .title-info-cause { margin-left:4% !important; position:unset !important; font-size:24px !important; font-weight: bold; width:90%; margin-top:20px; }
  .doughnut { position: relative !important;left: 74.5% !important;top: -63% !important; font-size:24px !important; }
  .history-chart-mobile-bar { display:block !important; }
  .history-chart-mobile-bar-div { display:block !important; }
  .history-chart-mobile { display:block !important; }
  .history-chart { display:none !important; }
  .cause-legend-rect { position:unset !important;margin-left:8%; display: inline-block !important;  }
  .cause-legend-title { position:unset !important; width:20%; font-size:16px !important; margin-bottom: 6px; }
  .cause-legend-val { position:unset !important; width:15%;text-align:right; }
  .pef-legend-rect { display:block !important; }
  .img-logo2 { display:none !important; }
  .title-logo-text-area2 { display:none !important; }
  .title-info-user-info-title2 { display:none !important; }
  .title-info-user-u2 { display:none !important; }
  .title-info-user-i2 { display:none !important; }
  .title-info-user-h2 { display:none !important; }
  .title-info-user-d2 { display:none !important; }
  .page2-title { display:none !important; }
  .page2-title-sub { display:none !important; }
  .cause-title { position:unset !important;margin-left:4%;margin-top:20px;font-size:24px !important;font-weight: bold; }
  .cause-point { display:none !important; }
  .cause-history-chart-unit { display:none !important; }
  .pef-point { display:none !important; }
  .pef-title { margin-left: 4% !important;position:unset !important; font-size:24px !important;font-weight: bold;float:left !important; margin-top: 20px;}
  .pef-title-sub { margin-left: 4% !important;position:unset !important; font-size:14px !important;width:90%;display: inline-block; }
  .pef-legend-title1 { margin-top: 20px;position:unset !important; float: right !important; margin-right: 4%; }
  .pef-legend-rect1 { display:block !important;margin-top: 20px;position:unset !important; float: right !important; width:18px !important;height:18px !important; }
  .pef-legend-title2 { margin-top: 20px;position:unset !important; float: right !important; margin-right: 10px; }
  .pef-legend-rect2 { display:block !important;margin-top: 20px;position:unset !important; float: right !important; width:18px !important;height:18px !important; }
  .pef-summary {  margin-left: 4% !important; margin-top: 10px;width:92% !important;position:unset !important;box-shadow: 0 2px 2px 0 rgba(0,0,0,0.1); }
  .pef-summary-sub {  position:relative !important; display: inline-block; }
  .pef-summary-val { position:relative !important; display: inline-block;text-align: right; width:56% !important; }
  .pef-chart-mobile { display: block !important; overflow-x:scroll;height:273px;margin-top:20px;overflow-y:hidden;
  -ms-overflow-style: none; /* IE and Edge */
    scrollbar-width: none; /* Firefox */
   }
   .pef-chart-mobile::-webkit-scrollbar {
    display: none; /* Chrome, Safari, Opera*/
   }
   .pef-chart-mobile-inner { display:inline-block;height:100%;width:100px;background-size: contain;float:left; }
   .pef-pc { display:none !important; }
  
  
   .mobile-title { background-color:white; width:100%; }
   .card { box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2);margin-bottom: 10px;padding-top: 10px;padding-bottom: 10px;background-color:white; }
}
</style>
<body>
	<div class="background-wrap">
		<div class="page-1" style="display:block;float:left;width:1080px; height:2980px; position: relative;min-height: 1px;float: left; ">
			<img class="page-back-1" style="position:absolute;left:0px;top:0px;height:1480px;width:1080px;margin-bottom:20px" src="/resources/images/common/new_report_background_page_1.png">
			<img class="page-back-1" style="position:absolute;left:0px;top:1538px;height:1480px;width:1080px;" src="/resources/images/common/new_report_background_page_2.png">
			
			<div class="mobile-title">
				<img class="img-logo1" style="display:none;position:absolute;left:20px;top:20px;height:45px;width:45px;" src="/resources/images/common/web_logo.png">
				<div class="title-logo-text-area" style="position:absolute;left:85px;top:40px;width:30%;display:block;float:left;height:80px;" >
					<div style="height:58%%; font-size: 30px;font-weight: bold;"><%=searchStartMonth.getMonth()+1 %>월 천식 보고서</div>
					<div style="height:30%; font-size: 12px;"> 대한민국 1등 천식관리어플 숨케어</div>
				</div>
			</div>
			<div class="card">
				<div class="title-info-user-info-title1"style="display:none;position:absolute;left:20px;top:83px;height:40px;width:100%;background-color:white;font-size: 16px;font-weight: bold;">회원정보</div>
				<div class="title-info-user-u1" style="position:absolute; margin-left: 424px; top:45px;color:#707070;font-size:16px;width:300px;">회원정보 : 숨케어 (남 / 34세 )</div>
				<div class="title-info-user-i1" style="position:absolute; margin-left: 424px; top:75px;color:#707070;font-size:16px;width:300px;">천식여부 : <%=definiteDiagnosis %> (2019년03월01일)</div>
				<div class="title-info-user-h1" style="position:absolute; margin-left: 732px; top:45px;color:#707070;font-size:16px;width:340px;overflow: hidden;">진료병원 : 숨케어병원</div>
				<div class="title-info-user-d1" style="position:absolute; margin-left: 732px; top:75px;color:#707070;font-size:16px;width:340px;overflow: hidden;">담당의사 : 김의사(호흡기내과)</div>
			</div>
			<div class="title-info-user-info-line1"style="display:none;position:absolute;left:10px;top:100px;height:1px;width:1060px;background-color:#d5d5d5; margin-top: 20px;"></div>
			<div class="title-point" style="position:absolute;left:30px;top:147px; width: 12px;height: 12px;border-radius: 6px;background-color: #4e4e4e;"></div>
			<div class="card">
			<div class="title-info" style="position:absolute;left:52px;top:137px;font-size:23px;color: #3e3e3e;font-weight: bold;">복약 순응도</div>
			<div class="title-medi-legend1" style="position:absolute;left:920px;top:140px;color: #33d16b;font-size:14px;margin-left:5px;">일반사용</div>
			<div class="title-medi-legend-rect1" style="display:none;position:absolute;left:870px;top:125px;width:20px;height:20px;border-radius: 2px;background-color: #33d16b;"></div>
			<div class="title-medi-legend2" style="position:absolute;left:994px;top:140px;color: #fd9393;font-size:14px;margin-left:5px; ">응급사용</div>
			<div class="title-medi-legend-rect2" style="display:none;position:absolute;left:960px;top:125px;width:20px;height: 20px;border-radius:2px;background-color: #fd9393;"></div>
			<div class="title-medicine-comment" style="position:absolute;margin-left:178px;top:140px;font-size:14px;color: #707070;margin-top: 3px">약 복용이 의사의 처방과 일치하는 정도</div>
			<%
			double mediTotalPerSum = 0;
			double mediTotalPerCnt = 0;
			for(int i=0;i<mediNoArr.size();i++){
				int emgMedi = 0;
				int norMedi = 0;
				for(int j=0;j<arrFeed_MEDI.size();j++){
					if(arrFeed_MEDI.get(j).MEDICINE_NO == mediNoArr.get(i)){
						if(arrFeed_MEDI.get(j).EMERGENCY_FLAG == 2){
							emgMedi++;
						}else{
							norMedi++;
						}
					}
				}
				if(mediFrqArr.get(i) !=-1){
					mediTotalPerSum += (emgMedi+norMedi)/(mediGoalCount.get(i)*mediFrqArr.get(i));
					mediTotalPerCnt++;
				}
				
				%>
			<%}
			String mediForMonth = "33 %";
			%>
			<div class="overall-medi1" style="position:absolute;left:30px;top:180px;width: 332px;height: 60px;border-radius: 4px;background-color: #dff5e0;">
				<div class="overall-medi-title1"style="width: 40%;position:absolute;left:12px;top:20px;font-size:14px;">평균 복약 순응도</div>
				<div class="overall-medi-val3" style="width: 30%;position:absolute;right:18px;top:18px;font-size:20px;text-align: right;font-weight: bold;"><%=mediForMonth%></div>
			</div>
			<div class="overall-medi2"style="position:absolute;left:374px;top:180px;width: 332px;height: 60px;border-radius: 4px;background-color: #dff5e0;">
				<div class="overall-medi-title2"style="width: 40%;position:absolute;left:12px;top:20px;font-size:14px;">응급약 총 사용 횟수</div>
				<div class="overall-medi-val2" style="width: 30%;position:absolute;right:18px;top:18px;font-size:20px;text-align: right;font-weight: bold;"><%=totalEmergencyMedi %> 회</div>
			</div>
			<div class="overall-medi3"style="position:absolute;left:718px;top:180px;width: 332px;height: 60px;border-radius: 4px;background-color: #dff5e0;">
				<div class="overall-medi-title3"style="width: 50%;position:absolute;left:12px;top:18px;font-size:14px;">한달 동안 기록한 약 종류</div>
				<div class="overall-medi-val1" style="width: 30%;position:absolute;right:18px;top:18px;font-size:20px;text-align: right;font-weight: bold;">3 개</div>
			</div>
			<img class="mediList1" style="position:absolute;left:30px;top:252px;width: 332px;height: 144px;border-radius: 4px;" src="/resources/images/common/report_default.png"></img>
			<img class="mediList2" style="position:absolute;left:374px;top:252px;width: 332px;height: 144px;border-radius: 4px;" src="/resources/images/common/report_default.png"></img>
			<img class="mediList3" style="position:absolute;left:718px;top:252px;width: 332px;height: 144px;border-radius: 4px;" src="/resources/images/common/report_default.png"></img>
			<img class="mediList4" style="position:absolute;left:30px;top:408px;width: 332px;height: 144px;border-radius: 4px;" src="/resources/images/common/report_default.png"></img>
			<img class="mediList5" style="position:absolute;left:374px;top:408px;width: 332px;height: 144px;border-radius: 4px;" src="/resources/images/common/report_default.png"></img>
			<img class="mediList6" style="position:absolute;left:718px;top:408px;width: 332px;height: 144px;border-radius: 4px;" src="/resources/images/common/report_default.png"></img>
			<img class="mediList7" style="position:absolute;left:30px;top:564px;width: 332px;height: 144px;border-radius: 4px;" src="/resources/images/common/report_default.png"></img>
			<img class="mediList8" style="position:absolute;left:374px;top:564px;width: 332px;height: 144px;border-radius: 4px;" src="/resources/images/common/report_default.png"></img>
			<img class="mediList9" style="position:absolute;left:718px;top:564px;width: 332px;height: 144px;border-radius: 4px;" src="/resources/images/common/report_default.png"></img>
			<img class="mediList10" style="position:absolute;left:30px;top:720px;width: 332px;height: 144px;border-radius: 4px;" src="/resources/images/common/report_default.png"></img>
			<img class="mediList11" style="position:absolute;left:374px;top:720px;width: 332px;height: 144px;border-radius: 4px;" src="/resources/images/common/report_default.png"></img>
			<img class="mediList12" style="position:absolute;left:718px;top:720px;width: 332px;height: 144px;border-radius: 4px;" src="/resources/images/common/report_default.png"></img>
			<%
				int leftVal = 0, leftCnt=0;;
				int topVal = 0;
				for(int i=0;i<3;i++){
					
					String tempFreq="";
					if(i == 1){
						tempFreq = "필요시 복용";
					}else{
						tempFreq = "하루 "+ (i+1) +"번";
					}
					double eatMedicineForMonth = 0;
					int emgMedi = 3;
					int norMedi = 2;
					String goalStr = "";
						goalStr = String.valueOf((int)( Math.random() * 28 + 1));
					String mediPerStr = "필요시";
					double mediPer = 0;
					if(i == 1){
						mediPer = (emgMedi+norMedi)/((i*7)*(i*2));
						if((emgMedi+norMedi)==0){
							mediPer = 0;
						}
						if(mediPer >= 1){
							mediPerStr = ""+100+ "%";
						}else{
							mediPerStr = ""+String.format("%.2f",Math.random() *100) + "%";
						}
					}
					%>
					<div class="medi-card<%=i %>" style="position:absolute;left:<%=30+leftVal %>px;top:<%=250+topVal %>px;width: 332px;height: 144px;border-radius: 4px;border: solid 1px #acacac;background-color: #ffffff;">
					<%if(i == 0){ %>
						<div class="medi-card-name"style="position:absolute;left:12px;top:14px;width: 320px;font-size:18px;text-align: left; color: #343434;font-weight: bold;">기침약</div>
						<%}else if(i == 1){ %>
						<div class="medi-card-name"style="position:absolute;left:12px;top:14px;width: 320px;font-size:18px;text-align: left; color: #343434;font-weight: bold;">진해거담제</div>
						<%}else{%>
						<div class="medi-card-name"style="position:absolute;left:12px;top:14px;width: 320px;font-size:18px;text-align: left; color: #343434;font-weight: bold;">스테로이드제</div>
						<%} %>
						<div class="medi-card-line" style="position:absolute;left:12px;top:51px;width: 320px;height: 1px;background-color: #d5d5d5;"></div>
						<div class="medi-card-t1"style="position:absolute;left:12px;top:62px;width: 232px;font-size:16px;text-align: left; color: #707070;">목표횟수 : <%=goalStr %> (<%=tempFreq %>)</div>
						<div class="medi-card-t2"style="position:absolute;left:12px;top:86px;width: 160px;font-size:16px;text-align: left; color: #707070;">일반복용 : <%=norMedi %> 회</div>
						<div class="medi-card-t3"style="position:absolute;left:12px;top:110px;width: 160px;font-size:16px;text-align: left; color: #707070;">응급복용 : <%=emgMedi %> 회</div>
						<div class="medi-card-persent"style="position:absolute;left:263px;top:89px;width: 43px;font-size:14px;text-align: center; color: #707070;"><%=mediPerStr %></div>
						<canvas class="doughnut" id="doughnutChart<%=i%>" width="72" height="72" style="position:absolute;left:249px;top:62px;display:none;"></canvas>
					</div>
					<%
					leftVal+=344;//358
					leftCnt++;
					if(leftCnt==3){
						topVal+=156;
						leftVal = 0;
						leftCnt = 0;
					}
					
				}
			%>
			</div>
			<div class="card">
				<div class="pef-point"style="position:absolute;left:30px;top:1683px; width: 12px;height: 12px;border-radius: 6px;background-color: #4e4e4e;"></div>
				<div class="pef-title"style="position:absolute;left:52px;top:1661px;font-size:23px;color: #3e3e3e;font-weight: bold;">최대호기유속(PEF)</div>

				<div class="pef-title-sub"style="position:absolute;left:52px;top:1694px;font-size:14px;color: #707070;">숨을 최대한 들이마시고 내뱉었을 때 만들어지는 호기 속도의 최고치</div>
<!-- 				<div class="pef-pc"style="position:absolute;left:50px;top:1801px;font-size:18px;">날짜</div> -->
<!-- 				<div class="pef-pc"style="position:absolute;left:35px;top:1842px;font-size:16px;">최소/최대</div>			 -->
<!-- 				<div class="pef-pc"style="position:absolute;left:50px;top:2102px;font-size:18px;">날짜</div> -->
<!-- 				<div class="pef-pc"style="position:absolute;left:35px;top:2143px;font-size:16px;">최소/최대</div> -->
<!-- 				<div class="pef-pc"style="position:absolute;left:50px;top:2403px;font-size:18px;">날짜</div> -->
<!-- 				<div class="pef-pc"style="position:absolute;left:35px;top:2444px;font-size:16px;">최소/최대</div> -->
<!-- 				<div class="pef-pc"style="position:absolute;left:50px;top:2704px;font-size:18px;">날짜</div> -->
<!-- 				<div class="pef-pc"style="position:absolute;left:35px;top:2745px;font-size:16px;">최소/최대</div> -->
				<%
				for(int i=0;i<lastDay;i++){
					int wCnt = 0, hCnt = 0;//118, 301
					if( i < 8){
						hCnt = 0;
						wCnt = i;
					}else if( i < 16){
						hCnt = 1;
						wCnt = i-8;
					}else if( i < 24){
						hCnt = 2;
						wCnt = i-16;
					}else{
						hCnt = 3;
						wCnt = i-24;
					}
					%>
					<div class="pef-pc"style="position:absolute;left:<%=166+114*wCnt%>px;top:<%=1801+292*hCnt%>px;font-size:18px;width:54px;text-align:center;"><%=(searchStartMonth.getMonth()+1)+"" %>/<%=(i+1)+"" %></div>
<%-- 					<div class="pef-pc"style="position:absolute;left:<%=140+118*wCnt%>px;top:<%=1842+301*hCnt%>px;font-size:16px;">최소</div> --%>
<%-- 					<div class="pef-pc"style="position:absolute;left:<%=199+118*wCnt%>px;top:<%=1842+301*hCnt%>px;font-size:16px;">최대</div> --%>
				<%
				}
				%>
				<%
				ArrayList<Integer> MaxPEFArr = new ArrayList<Integer>();
				ArrayList<Integer> MinPEFArr = new ArrayList<Integer>();
				ArrayList<String> datePEFArr = new ArrayList<String>();
				ArrayList<Integer> inspiratorPEFMinArr = new ArrayList<Integer>();
				ArrayList<Integer> inspiratorPEFMaxArr = new ArrayList<Integer>();
				//INSPIRATOR_FLAG=1 -> 흡입기 사용
				double dValue = Math.random();
				int iValue = (int)(dValue * 30);
				int flag = (int)(dValue + 1);
				for(int i=0;i<lastDay;i++){
					if( datePEFArr.contains((GF.stringToDate(arrFeed_reg.get(i)).getDate()+""))==false ){
						String temp = GF.stringToDate(arrFeed_reg.get(i)).getDate()+"";
						datePEFArr.add(temp);
						MaxPEFArr.add(arrFeed_PEF.get(i));
						MinPEFArr.add(arrFeed_PEF.get(i) - iValue);
						inspiratorPEFMinArr.add(arrFeed_flag.get(i) + flag);
						inspiratorPEFMaxArr.add(arrFeed_flag.get(i) - flag);
					}else{//해당 날짜에 다른 데이터 존재
						int idx = datePEFArr.indexOf((GF.stringToDate(arrFeed_reg.get(i)).getDate()+""));
						if(MaxPEFArr.get(idx) < arrFeed_PEF.get(i)){
							MaxPEFArr.set(idx , arrFeed_PEF.get(i));
							inspiratorPEFMaxArr.set(idx, arrFeed_flag.get(i)+ flag);
						}
						if(MinPEFArr.get(idx) > arrFeed_PEF.get(i)){
							MinPEFArr.set(idx , arrFeed_PEF.get(i));
							inspiratorPEFMinArr.set(idx, arrFeed_flag.get(i)+ flag);
						}
					}
				}
				double changeAvg = 0;
				double changeSum = 0;
				double changeCnt = 0;
				for(int j=0;j<datePEFArr.size();j++){
					int wCnt = 0, hCnt = 0;//118, 301
					
					if( Integer.parseInt(datePEFArr.get(j)) <= 8){
						hCnt = 0;
						wCnt = Integer.parseInt(datePEFArr.get(j));
					}else if( Integer.parseInt(datePEFArr.get(j)) <= 16){
						hCnt = 1;
						wCnt = Integer.parseInt(datePEFArr.get(j))-8;
					}else if( Integer.parseInt(datePEFArr.get(j)) <= 24){
						hCnt = 2;
						wCnt = Integer.parseInt(datePEFArr.get(j))-16;
					}else{
						hCnt = 3;
						wCnt = Integer.parseInt(datePEFArr.get(j))-24;
					}
// 					if(MaxPEFArr.get(j) == MinPEFArr.get(j)){
						//최대값만 표현
						//색상 결정
// 						String temp = "report_pef_green.png";
// 						if(inspiratorPEFMaxArr.get(j)==1){
// 							temp = "report_pef_red.png";
// 						}
// 						int maxPoint = ((maxPEF/100)+1)*100;
// 						int realHeight = 180-(int)((double)MaxPEFArr.get(j)/(double)maxPoint*180.0);
					%>
<%-- 					<img class="pef-pc"style="position:absolute;left:<%=207+((wCnt-1)*114)%>px;top:<%=1888+hCnt*301+realHeight%>px;;color:#ffffff; width: 32px;" src="/resources/images/common/<%=temp%>"></img> --%>
<%-- 					<div class="pef-pc"style="position:absolute;left:<%=207+((wCnt-1)*114)%>px;top:<%=1888+hCnt*301+realHeight%>px;;color:#ffffff; width: 32px;text-align:center;"><%=MaxPEFArr.get(j) %></div> --%>
					<%
// 					}else{
						String temp1 = "report_pef_green.png";
						String temp2 = "report_pef_red.png";
						if(inspiratorPEFMinArr.get(j)==1){
							temp1 = "report_pef_green.png";
						}else{
							temp1 = "report_pef_red.png";
						}
						if(inspiratorPEFMaxArr.get(j)==1){
							temp2 = "report_pef_green.png";
						}else{
							temp2 = "report_pef_red.png";
						}
						int maxPoint = ((maxPEF/100)+1)*100;
						
						int realMaxHeight = MaxPEFArr.get(j)%100;
						int realMinHeight = MinPEFArr.get(j)%100;
						
						int realMaxHeightH = MaxPEFArr.get(j)/100;
						int realMinHeightH = MinPEFArr.get(j)/100;
						
						int realyAxis = 0;
						double maxMovePosition = 0;
						double minMovePosition = 0;
						maxMovePosition = -((realMaxHeightH - (avg/100))*yAxisHeight + (realMaxHeight*(yAxisHeight/100)));
						minMovePosition = -((realMinHeightH - (avg/100))*yAxisHeight + (realMinHeight*(yAxisHeight/100)));
						
						changeSum +=(double)MaxPEFArr.get(j) - (double)MinPEFArr.get(j);
						changeCnt++;
						%>
						<%if(inspiratorPEFMinArr.get(j) == 1){ %>
							<img class="pef-pc"style="position:absolute;left:<%=150+((wCnt-1)*114)%>px;top:<%=1964+hCnt*292 + minMovePosition%>px;;color:#ffffff; width: 32px;" src="/resources/images/common/<%=temp2%>"></img>
						<%}else{ %>
							<img class="pef-pc"style="position:absolute;left:<%=150+((wCnt-1)*114)%>px;top:<%=1964+hCnt*292 + minMovePosition%>px;;color:#ffffff; width: 32px;" src="/resources/images/common/<%=temp1%>"></img>
						<%} %>
						<div class="pef-pc"style="position:absolute;left:<%=150+((wCnt-1)*114)%>px;top:<%=1964+hCnt*292  + minMovePosition%>px;color:#ffffff; width: 32px;text-align:center;"><%=MinPEFArr.get(j) %></div>
						<%if(inspiratorPEFMaxArr.get(j) == 1){ %>
							<img class="pef-pc"style="position:absolute;left:<%=207+((wCnt-1)*114)%>px;top:<%=1964+hCnt*292 + maxMovePosition%>px;;color:#ffffff; width: 32px;" src="/resources/images/common/<%=temp2%>"></img>
						<%}else{ %>
							<img class="pef-pc"style="position:absolute;left:<%=207+((wCnt-1)*114)%>px;top:<%=1964+hCnt*292 + maxMovePosition%>px;;color:#ffffff; width: 32px;" src="/resources/images/common/<%=temp1%>"></img>
						<%} %>
						<div class="pef-pc"style="position:absolute;left:<%=207+((wCnt-1)*114)%>px;top:<%=1964+hCnt*292 + maxMovePosition%>px;;color:#ffffff; width: 32px;text-align:center;"><%=MaxPEFArr.get(j) %></div>
						<%
					}
// 				}
				String changeAvgStr = "No Data.";
				if(maxPEF!=-1){
					changeAvg = changeSum/((double)maxPEF*changeCnt)*100.0;
					changeAvgStr = String.format("%.2f",changeAvg)+"%";
				}
				%>
				
				<%for(int i=0;i<yAxisCnt;i++){%>
					<div class="pef-pc"style="position:absolute;left:45px;top:<%=1864+(i*yAxisHeight) + yAxisHeight/2%>px;font-size:14px;width:50px;text-align:right;"><%=axisMaxPEFRS-(100*i) %></div>
					<div class="pef-pc"style="position:absolute;left:45px;top:<%=2156+(i*yAxisHeight) + yAxisHeight/2%>px;font-size:14px;width:50px;text-align:right;"><%=axisMaxPEFRS-(100*i) %></div>
					<div class="pef-pc"style="position:absolute;left:45px;top:<%=2448+(i*yAxisHeight) + yAxisHeight/2%>px;font-size:14px;width:50px;text-align:right;"><%=axisMaxPEFRS-(100*i) %></div>
					<div class="pef-pc"style="position:absolute;left:45px;top:<%=2740+(i*yAxisHeight) + yAxisHeight/2%>px;font-size:14px;width:50px;text-align:right;"><%=axisMaxPEFRS-(100*i) %></div>
				<%}%>
				
				<div class="pef-summary" style="position:absolute;left:30px;top:1718px;width: 332px;height: 60px;border-radius: 4px;background-color: #dff5e0;">
					<div class="pef-summary-sub"style="width: 40%;position:absolute;left:12px;top:20px;font-size:14px;">한달 간 최고 수치</div>
					<div class="pef-summary-val" style="width: 30%;position:absolute;right:18px;top:18px;font-size:20px;text-align: right;font-weight: bold;"><%=maxPEFRS %></div>
				</div>
				<div class="pef-summary"style="position:absolute;left:374px;top:1718px;width: 332px;height: 60px;border-radius: 4px;background-color: #dff5e0;">
					<div class="pef-summary-sub"style="width: 40%;position:absolute;left:12px;top:20px;font-size:14px;">한달 간 최소 수치</div>
					<div class="pef-summary-val" style="width: 30%;position:absolute;right:16px;top:18px;font-size:20px;text-align: right;font-weight: bold;"><%=minPEFRS %></div>
				</div>
				<div class="pef-summary"style="position:absolute;left:718px;top:1718px;width: 332px;height: 60px;border-radius: 4px;background-color: #dff5e0;">
					<div class="pef-summary-sub"style="width: 40%;position:absolute;left:12px;top:20px;font-size:14px;">일 평균 변동률</div>
					<div class="pef-summary-val"style="width: 30%;position:absolute;right:16px;top:18px;font-size:20px;text-align: right;font-weight: bold;"><%=changeAvgStr %></div>
				</div>
				<div class="pef-legend-title1" style="position:absolute;left:862px;top:1678px;color: #33d16b;font-size:14px;margin-left:5px;">흡입기 미사용</div>
				<div class="pef-legend-rect1" style="display:none;position:absolute;left:877px;top:1667px;width:20px;height:20px;border-radius: 2px;background-color: #33d16b;"></div>
				<div class="pef-legend-title2" style="position:absolute;left:982px;top:1678px;color: #f57020;font-size:14px;margin-left:5px; ">흡입기 사용</div>
				<div class="pef-legend-rect2" style="display:none;position:absolute;left:995px;top:1667px;width:20px;height: 20px;border-radius:2px;background-color: #f57020;"></div>
				<div class="pef-chart-mobile" style="width:100%;margin-left:0%;display:none;">
				<%
				int pefGraphCol = lastDay;
				int pefCalcWidth = ((pefGraphCol-1)*100) + 198;
				%>
					<div style="margin-left:10px;width:<%=pefCalcWidth%>px;height:273px;white-space: nowrap;position:relative;margin-top:10px;">
					<%
					for(int i=0;i<lastDay;i++){
						int wCnt = 0;
						%>
						<%
						if(i==0){
							%>
							<div style="width:198px; background-image:url('/resources/images/common/report_pef_chart_left.png');background-repeat:no-repeat;"class="pef-chart-mobile-inner">
							<div style="position:absolute;left:19px;top:8px;width:50px;text-align:center">날짜</div>
							<div style="position:absolute;left:11px;top:40px;width:75px;text-align:center">최소/최대</div>
							<%
							if(yAxisCnt != 0){
								yAxisHeight = 178/yAxisCnt;
							}
							for(int j=0;j<yAxisCnt;j++){%>
								<div style="position:absolute;left:10px;top:<%=59.5+(j*yAxisHeight)+yAxisHeight/2%>px;font-size:14px;width:50px;text-align:right;"><%=axisMaxPEFRS-(100*j) %></div>
							<%}%>
							<div style="z-index:90;position:absolute;left:122px;top:8px;width:50px;text-align:center"><%=(searchStartMonth.getMonth()+1)+"" %>/<%=(i+1)+"" %></div>
							<div style="z-index:90;position:absolute;left:103px;top:40px;width:40px;text-align:center">최소</div>
							<div style="z-index:90;position:absolute;left:153px;top:40px;width:40px;text-align:center">최대</div>
							</div>
							<% 
						}else{
							%>
							<div style="z-index:90;position:relative;background-image:url('/resources/images/common/report_pef_chart_right.png');background-repeat:no-repeat;" class="pef-chart-mobile-inner">
							<div style="z-index:90;position:absolute;left:23px;top:8px;width:50px;text-align:center"><%=(searchStartMonth.getMonth()+1)+"" %>/<%=(i+1)+"" %></div>
							<div style="z-index:90;position:absolute;left:5px;top:40px;width:40px;text-align:center">최소</div>
							<div style="z-index:90;position:absolute;left:55px;top:40px;width:40px;text-align:center">최대</div>
							</div>
							<%
						}
						if(MaxPEFArr.size() > i){
						wCnt = Integer.parseInt(datePEFArr.get(i));
						
// 							if(MaxPEFArr.get(i) == MinPEFArr.get(i)){
// 								//최대값만 표현
// 								//색상 결정
// 								String temp = "#33d16b";
// 								if(inspiratorPEFMaxArr.get(i)==1){
// 									temp = "#f57020";
// 								}
// 								int maxPoint = ((maxPEF/100)+1)*100;
// 								int realHeight = 0;
// 								if(minPEF <100){
// 									realHeight = 180-(int)((double)MaxPEFArr.get(i)/(double)maxPoint*190.0);
// 								}else{
// 									realHeight = 180-(int)((double)MaxPEFArr.get(i)/(double)maxPoint*175.0);
// 								}
							%>
<%-- 							<img style="z-index:99;position:absolute;left:<%=158+((wCnt-1)*100)%>px;top:<%=60+realHeight%>px;;color:#ffffff; width: 32px;" src="/resources/images/common/<%=temp%>"></img> --%>
<%-- 							<div style="z-index:99;position:absolute;left:<%=158+((wCnt-1)*100)%>px;top:<%=60+realHeight%>px;;color:#ffffff; width: 32px;text-align:center;font-size: 12px;font-weight: 500;"><%=MaxPEFArr.get(i) %></div> --%>
							<%
// 							}else{
								String temp1 = "report_pef_green.png";
								String temp2 = "report_pef_green.png";
								if(inspiratorPEFMinArr.get(i)==1){
									temp1 = "report_pef_green.png";
								}else{
									temp1 = "report_pef_red.png";
								}
								if(inspiratorPEFMaxArr.get(i)==1){
									temp2 = "report_pef_green.png";
								}else{
									temp2 = "report_pef_red.png";
								}
								int maxPoint = ((maxPEF/100)+1)*100;
								
								int realMaxHeight = MaxPEFArr.get(i)%100;
								int realMinHeight = MinPEFArr.get(i)%100;
								
								int realMaxHeightH = MaxPEFArr.get(i)/100;
								int realMinHeightH = MinPEFArr.get(i)/100;
								
								int realyAxis = 0;
								double maxMovePosition = 0;
								double minMovePosition = 0;
								maxMovePosition = -((realMaxHeightH - (avg/100))*yAxisHeight + (realMaxHeight*(yAxisHeight/100)));
								minMovePosition = -((realMinHeightH - (avg/100))*yAxisHeight + (realMinHeight*(yAxisHeight/100)));
								
								changeSum +=(double)MaxPEFArr.get(i) - (double)MinPEFArr.get(i);
								changeCnt++;
								%>
								<%if(inspiratorPEFMinArr.get(i) == 1){ %>
									<img style="z-index:99;position:absolute;left:<%=107+((wCnt-1)*100)%>px;top:<%=148+minMovePosition%>px;;color:#ffffff; width: 32px;" src="/resources/images/common/<%=temp2%>"></img>
								<%}else{ %>
									<img style="z-index:99;position:absolute;left:<%=107+((wCnt-1)*100)%>px;top:<%=148+minMovePosition%>px;;color:#ffffff; width: 32px;" src="/resources/images/common/<%=temp1%>"></img>
								<%} %>
								<div style="z-index:99;position:absolute;left:<%=107+((wCnt-1)*100)%>px;top:<%=149+minMovePosition%>px;color:#ffffff; width: 32px;text-align:center;font-size: 12px;font-weight: 500;"><%=MinPEFArr.get(i) %></div>
								<%if(inspiratorPEFMaxArr.get(i) == 1){ %>
									<img style="z-index:99;position:absolute;left:<%=158+((wCnt-1)*100)%>px;top:<%=148+maxMovePosition%>px;;color:#ffffff; width: 32px;" src="/resources/images/common/<%=temp2%>"></img>
								<%}else{ %>
									<img style="z-index:99;position:absolute;left:<%=158+((wCnt-1)*100)%>px;top:<%=148+maxMovePosition%>px;;color:#ffffff; width: 32px;" src="/resources/images/common/<%=temp1%>"></img>
								<%} %>
								<div style="z-index:99;position:absolute;left:<%=158+((wCnt-1)*100)%>px;top:<%=149+maxMovePosition%>px;;color:#ffffff; width: 32px;text-align:center;font-size: 12px;font-weight: 500;"><%=MaxPEFArr.get(i) %></div>
								<%
							}
						}
					%>
					<%
// 					}
					%>
					</div>
				</div>
			</div>
			<div class="card">
		 		<!-- 증상요약 영역 -->
				<div class="title-point" style="position:absolute;left:30px;top:897px; width: 12px;height: 12px;border-radius: 6px;background-color: #4e4e4e;"></div>
				<div class="title-info-cause" style="position:absolute;left:55px;top:887px;font-size:23px;color: #3e3e3e;font-weight: bold;">증상 요약</div>
	 			<div class="card-cause1" style="position:absolute;left:30px;top:935px;width: 332px;height: 60px;border-radius: 4px;background-color: #dff5e0;">
					<div class="card-cause-title" style="position:absolute;width:38%;left:12px;top:20px;font-size:14px;">증상 있었던 날</div>
					<div class="card-cause-val" style="position:absolute;width:38%;right:18px;top:16px;font-size:20px;text-align: right;font-weight: bold;"><%=causeCnt %>일/<%=lastDay %>일</div>
				</div>
				<div class="card-cause2" style="position:absolute;left:374px;top:935px;width: 332px;height: 60px;border-radius: 4px;background-color: #dff5e0;">
					<div class="card-cause-title" style="position:absolute;width:38%;left:12px;top:20px;font-size:14px;">야간 증상</div>
					<div class="card-cause-val" style="position:absolute;width:38%;right:18px;top:16px;font-size:20px;text-align: right;font-weight: bold;"><%=nightSickCnt %>일/<%=lastDay %>일</div>
				</div>
				<div class="card-cause3" style="position:absolute;left:719px;top:935px;width: 332px;height: 60px;border-radius: 4px;background-color: #dff5e0;">
					<div class="card-cause-title" style="position:absolute;width:38%;left:12px;top:20px;font-size:14px;">천식조절검사(ACT)</div>
					<div class="card-cause-val" style="position:absolute;width:38%;right:18px;top:16px;font-size:20px;text-align: right;font-weight: bold;"><%=actRs %></div>
				</div>
				<!-- 시간대별 증상 영역 -->
				<div class="cause-point"style="position:absolute;left:30px;top:1028px; width: 12px;height: 12px;border-radius: 6px;background-color: #4e4e4e;"></div>
				<div class="cause-title"style="position:absolute;left:55px;top:1017px;font-size:23px;color: #3e3e3e;font-weight:bold;">시간대 별 증상</div>
				<div class="history-chart-mobile-bar-div" style="position:relative;border-radius: 25px;border-collapse: separate; z-index: 1;height:32px;overflow:hidden;margin-top:20px;margin-left:4%;width:92%;display:none;"><canvas class="history-chart-mobile-bar" id="chartJSContainerMobileBar" style="width:100%;height:74px;margin-top: -14px; margin-bottom: -7px;display:none;"></canvas></div>
				
				<div class="cause-legend-rect" style="position:absolute;margin-left:5.6%;margin-top:10px;display:none;left:46px;top:1114px;width: 12px;height: 12px;border-radius: 25px;background-color: #364064;"></div>
				<div class="cause-legend-title" style="position:absolute;display:inline-block;left:46px;top:1070px;font-size:14px;color: #364064;">기침</div>
				<div class="cause-legend-val" style="position:absolute;display:inline-block;left:113px;top:1067px;font-size:20px;color: #364064;font-weight: bold;"><%=totalCoughCnt %>회</div>
				
				<div class="cause-legend-rect" style="position:absolute;margin-left:6%;margin-top:10px;display:none;left:46px;top:1114px;width: 12px;height: 12px;border-radius: 25px;background-color: #8da3c4;"></div>
				<div class="cause-legend-title" style="position:absolute;display:inline-block;left:193px;top:1070px;font-size:14px;color: #8da3c4;">가래</div>
				<div class="cause-legend-val" style="position:absolute;display:inline-block;left:260px;top:1067px;font-size:20px;color: #8da3c4;font-weight: bold;"><%=totalPhlegmCnt %>회</div>
				
				<div class="cause-legend-rect" style="position:absolute;margin-left:5.6%;display:none;left:655px;top:1114px;width: 12px;height: 12px;border-radius: 25px;background-color: #bec7d0;"></div>
				<div class="cause-legend-title" style="position:absolute;display:inline-block;left:340px;top:1070px;font-size:14px;color: #bec7d0;">가슴답답</div>
				<div class="cause-legend-val" style="position:absolute;display:inline-block;left:407px;top:1067px;font-size:20px;color: #bec7d0;font-weight: bold;"><%=totalChestCnt %>회</div>
				
				<div class="cause-legend-rect" style="position:absolute;margin-left:6%;display:none;left:449px;top:1114px;width: 12px;height: 12px;border-radius: 25px;background-color: #f07a55;"></div>
				<div class="cause-legend-title" style="position:absolute;display:inline-block;left:486px;top:1070px;font-size:14px;color: #f07a55;">숨쉬기 불편</div>
				<div class="cause-legend-val" style="position:absolute;display:inline-block;left:553px;top:1067px;font-size:20px;color: #f07a55;font-weight: bold;"><%=totalBreathCnt %>회</div>
				
				<div class="cause-legend-rect" style="position:absolute;margin-left:5.6%;display:none;left:257px;top:1114px;width: 12px;height: 12px;border-radius: 25px;background-color: #f7c24f;"></div>
				<div class="cause-legend-title" style="position:absolute;display:inline-block;left:632px;top:1070px;font-size:14px;color: #f7c24f;">천명음</div>
				<div class="cause-legend-val" style="position:absolute;display:inline-block;left:699px;top:1067px;font-size:20px;color: #f7c24f;font-weight: bold;"><%=totalRoaringCnt %>회</div>
				
				<div class="cause-legend-rect" style="position:absolute;margin-left:6%;display:none;left:868px;top:1114px;width: 12px;height: 12px;border-radius: 25px;background-color: #1388ac;"></div>
				<div class="cause-legend-title" style="position:absolute;display:inline-block;left:779px;top:1070px;font-size:14px;color: #1388ac;">기타증상</div>
				<div class="cause-legend-val" style="position:absolute;display:inline-block;left:846px;top:1067px;font-size:20px;color: #1388ac;font-weight: bold;"><%=totalEtcCnt %>회</div>
				
				<div class="cause-legend-rect" style="position:absolute;margin-left:5.6%;display:none;left:868px;top:1114px;width: 12px;height: 12px;border-radius: 25px;background-color: #8d8d8d;"></div>
				<div class="cause-legend-title" style="position:absolute;display:inline-block;left:926px;top:1070px;font-size:14px;color: #8d8d8d;">증상없음</div>
				<div class="cause-legend-val" style="position:absolute;display:inline-block;left:993px;top:1067px;font-size:20px;color: #8d8d8d;font-weight: bold;"><%=totalNoSymptomCnt %>회</div>
				
				<div class="cause-history-chart-unit" style="position:absolute;display:inline-block;left:993px;top:1101px; font-weight: bold;font-size:12px;color: #000000;">단위(회)</div>
				<canvas class="history-chart" id="chartJSContainer" style="position:absolute;left:40px;top:1132px;width:1000px;height:350px;"></canvas>
				<canvas class="history-chart-mobile" id="chartJSContainerMobile" style="margin-left:4%;margin-top:20px;width:92%;height:200px;display:none;"></canvas>
				<!-- page 2 : height: +1538px; => 0 -->
				<img class="img-logo2" style="display:none;position:absolute;left:20px;top:1558px;height:45px;width:45px;" src="/resources/images/common/web_logo.png">
				<div class="title-logo-text-area2" style="position:absolute;left:85px;top:1578px;width:30%;display:block;float:left;height:80px;" >
					<div class="page2-title"style="height:58%%; font-size: 30px;font-weight:bold;"><%=searchStartMonth.getMonth()+1 %>월 천식 보고서</div>
					<div class="page2-title-sub"style="height:30%; font-size: 12px;">대한민국 1등 천식관리어플 숨케어</div>
				</div>
				<div class="title-info-user-u2" style="position:absolute; margin-left: 424px; top:1583px;color:#707070;font-size:16px;width:300px;">회원정보 : <%=arrUser.get(0).NAME %> (<%=gender %> / <%=GF.getAge(Integer.toString(arrUser.get(0).BIRTH)) %>세 )</div>
				<div class="title-info-user-i2" style="position:absolute; margin-left: 424px; top:1613px;color:#707070;font-size:16px;width:300px;">천식여부 : <%=definiteDiagnosis %> (<%=arrUser.get(0).OUTBREAK_DT %>)</div>
				<div class="title-info-user-h2" style="position:absolute; margin-left: 732px; top:1583px;color:#707070;font-size:16px;width:340px;overflow: hidden;">진료병원 : <%=hosName %></div>
				<div class="title-info-user-d2" style="position:absolute; margin-left: 732px; top:1613px;color:#707070;font-size:16px;width:340px;overflow: hidden;">담당의사 : <%=docName %> <%=department %></div>
			</div>
		</div> 
	</div>
	<script>
		function loadChart() {
			var coughBuff="<%=coughBuff%>";
			var coughBuffArray=coughBuff.split(",");
			var breathBuff="<%=breathBuff%>";
			var breathBuffArray=breathBuff.split(",");
			var roaringBuff="<%=roaringBuff%>";
			var roaringBuffArray=roaringBuff.split(",");
			var chestBuff="<%=chestBuff%>";
			var chestBuffArray=chestBuff.split(",");
			var phlegmBuff="<%=phlegmBuff%>";
			var phlegmBuffArray=phlegmBuff.split(",");
			var noSymptomBuff="<%=noSymptomBuff%>";
			var noSymptomBuffArray=noSymptomBuff.split(",");
			var etcBuff="<%=etcBuff%>";
			var etcBuffArray=etcBuff.split(",");
// 			var totalArraySize = coughBuffArray.length +breathBuffArray.length +roaringBuffArray.length +chestBuffArray.length +phlegmBuffArray.length +noSymptomBuffArray.length + etcBuffArray.length;

			/* history chart */
			var historyChartColors = { cc1: 'rgb(6, 73, 89)', cc2: 'rgb(141, 163, 196)',cc3: 'rgb(190, 199, 208)',cc4: 'rgb(240, 122, 85)',cc5: 'rgb(247, 194, 79)',cc6: 'rgb(19, 136, 172)',cc7: 'rgb(141, 141, 141)'};
			var historyData = {
					labels: ["아침(06:00~)", "점심(12:00~)", "저녁(18:00~)", "밤(24:00~)"],
					datasets: [
				        {label: "기침",backgroundColor: historyChartColors.cc1,data: coughBuffArray},
				        {label: "가래",backgroundColor: historyChartColors.cc2,data: phlegmBuffArray},
				        {label: "가슴답답",backgroundColor: historyChartColors.cc3,data: chestBuffArray},
				        {label: "숨쉬기 불편",backgroundColor: historyChartColors.cc4,data: breathBuffArray},
				        {label: "천명음",backgroundColor: historyChartColors.cc5,data: roaringBuffArray},
				        {label: "기타증상",backgroundColor: historyChartColors.cc6,data: etcBuffArray},
				        {label: "증상없음",backgroundColor: historyChartColors.cc7,data: noSymptomBuffArray},
				    ]};

			var historyChartOptions = {
				type: 'bar',
				data: historyData,
				options: {
					responsive: false,
					scales: {yAxes: [{ticks: {min: 0,reverse: false}}],xAxes: [{ticks: {fontSize:15}}]},
					legend: { display:false }
				}
			}
			var mobileHistoryChartOptions = {
					type: 'bar',
					data: historyData,
					options: {
						responsive: false,
						scales: { xAxes: [{stacked: true, barPercentage: 0.4 }],yAxes: [{ticks: {beginAtZero: true,callback: function(value) {if (value % 1 === 0) {return value;}}}, stacked: true}]},
						legend: { display:false }
					}
			}
			var barData = {
		        labels: ["기침"],
		        datasets: [{
		            data: [<%=totalCoughCnt%>],
		            backgroundColor: "rgb(6, 73, 89)",
		        },{
		            data: [<%=totalRoaringCnt%>],
		            backgroundColor: "rgb(247, 194, 79)",
		        },{
		            data: [<%=totalBreathCnt%>],
		            backgroundColor: "rgb(240, 122, 85)",
		        },{
		            data: [<%=totalChestCnt%>],
		            backgroundColor: "rgb(190, 199, 208)",
		        },{
		            data: [<%=totalPhlegmCnt%>],
		            backgroundColor: "rgb(141, 163, 196)",
		        },{
		            data: [<%=totalNoSymptomCnt%>],
		            backgroundColor: "rgb(141, 141, 141)",
		        },{
		            data: [<%=totalEtcCnt%>],
		            backgroundColor: "rgb(19, 136, 172)",
		        }]
		    };
			var totalArraySize  = (<%=totalCoughCnt%> +<%=totalRoaringCnt%> +<%=totalBreathCnt%> +<%=totalChestCnt%> +<%=totalNoSymptomCnt%> +<%=totalEtcCnt%> )
			var mobileHistoryBarChartOptions = {
					type: 'horizontalBar',
					data: barData,
					options: {
						responsive: false,
						tooltips: {enabled: false},
						scales: { xAxes: [{barPercentage: 0.1, display: false,stacked: true, ticks:{max:totalArraySize}}],yAxes: [{display: false,stacked: true }]},
						legend:{ display:false},
						animation: { duration: 0},
					    hover: { animationDuration: 0},
					    responsiveAnimationDuration: 0
					}
			};
			

			var historyCtx = document.getElementById('chartJSContainer').getContext('2d');
			new Chart(historyCtx, historyChartOptions);
			var mobileHistoryCtx = document.getElementById('chartJSContainerMobile').getContext('2d');
			new Chart(mobileHistoryCtx, mobileHistoryChartOptions);
			var mobileHistoryBarCtx = document.getElementById('chartJSContainerMobileBar').getContext('2d');
			new Chart(mobileHistoryBarCtx, mobileHistoryBarChartOptions);
			<%
			for(int i=0;i<3;i++){
				int emgMedi = 3;
				int norMedi = 5;
// 				for(int j=0;j<arrFeed_MEDI.size();j++){
// 					if(arrFeed_MEDI.get(j).MEDICINE_NO == mediNoArr.get(i)){
// 						if(arrFeed_MEDI.get(j).EMERGENCY_FLAG == 2){
// 							emgMedi++;
// 						}else{
// 							norMedi++;
// 						}
// 					}
// 				}
				int loss = (int)( Math.random() * 20 + 1)  - (emgMedi+norMedi);
				if(loss<0){
					loss = 0;
				}
				String piBuff = "";
				if(i != 1){
					emgMedi = 0;
					norMedi = 0;
					loss=100;
				}else{
					if(emgMedi+norMedi==0){
						emgMedi = 0;
						norMedi = 0;
						loss=100;
					}
				}
				piBuff = ""+norMedi+","+emgMedi+","+loss;
			%>
			var pieBuff="<%=piBuff%>";
			var pieBuffArray=pieBuff.split(",");
			var colors = [
				  'rgb(51, 211, 107)',
				  'rgb(253, 147, 147)',
				  'rgb(191, 191, 191)'
				];
			var data = pieBuffArray;
			var bgColor = colors;
			var dataChart = {
			  datasets: [{
			    data: data,
			    backgroundColor: bgColor
			  }]
			};
			var config = {
					  type: 'doughnut',
					  data: dataChart,
					  options: {
						  tooltips: {
						        enabled: false
						    },
						cutoutPercentage: 70,
					    legend: {
					      display: false
					    }
					  }
					};
			var ctx = document.getElementById("doughnutChart<%=i %>").getContext("2d");
			var doughnutChart = new Chart(ctx, config);
			<%
			}
			%>
		}
		loadChart();
		setTimeout(function() {
			<%
			for(int i=0;i<3;i++){
			%>
			document.getElementById("doughnutChart<%=i%>").style.width = "72px";
			document.getElementById("doughnutChart<%=i%>").style.height = "72px";
			document.getElementById("doughnutChart<%=i%>").style.display = "block";
			<%
			}%>
		}, 100);
	</script>
</body>
</html>