BEGIN {
  DMLIST=dmlist
  srand();
  MAX_POST_MATCHES = -1;
  LIVE_PLAY = 1; # 1 == LIVE RUN
  OUTPUT_MATCH_ID = "14052";

  getGames();
  tipGames();
  sendToBotLiga(); 
  print "DONE!";
}
#--------------------------------------------------------------------------------------------
function getMatchData(mid, hostid, guestid) {
  if (LIVE_PLAY==1 || (LIVE_PLAY==0 && gamesTipCounter==0)) {
    print "-- mid match data " mid;
    matchData = soapGetMatchDataByTeams(hostid,guestid);
    noGoalsCount = gsub(/<matchResults \/>/,"", matchData); 
    while (index(matchData, "<matchResult>") > 0) {
      start = index(matchData, "<matchResult>");
      end = index(matchData, "</matchResult>") + length("</matchResult>");
      subLine = substr(matchData, start, end - start); 
      match(subLine,/<pointsTeam1>(.?)[^<]*/, retGoalsT1);
      match(subLine,/<pointsTeam2>(.?)[^<]*/, retGoalsT2);
      goalsT1 += retGoalsT1[1];
      goalsT2 += retGoalsT2[1];
      if (retGoalsT1[1] > retGoalsT2[1]) {
        win++;
      } else if (retGoalsT1[1] == retGoalsT2[1]) {
        tie++;
      } else {
        lose++;
      }
      matchCount++;
      matchData = substr(matchData, end);
    }
    m[mid] = matchCount ":" goalsT1 ":" goalsT2 ":" win ":" tie ":" lose;
    split(m[mid],hostMatchSplit,":");
  }
}
function calHostGoals(mid) {
  hostRetVal = 2;
  if (hostMatchSplit[4] > hostMatchSplit[6]) {
    hostRetVal = int(rand()*3 + 0.5);
  } else if (hostMatchSplit[4] < hostMatchSplit[6]) {
    hostRetVal = int(rand()*1 + 0.5);
  } 
  if (gamesTipCounter==0) { print "-home " hostRetVal " " m[mid]; }
  return hostRetVal;
}
function calGuestGoals(mid) {
  hostRetVal = 1;
  if (hostMatchSplit[4] > hostMatchSplit[6]) {
    hostRetVal = int(rand()*1 + 0.5);
  } else if (hostMatchSplit[4] < hostMatchSplit[6]) {
    hostRetVal = int(rand()*3 + 0.5);
  } 
  if (gamesTipCounter==0) { print "-guest " hostRetVal " " m[mid]; }
  return hostRetVal;
}
function soapGetLeagues() {
  "curl -H \"Content-Type: text/xml; charset=utf-8\" \
        -H \"SOAPAction:\" \
        -d @getleagues.soap \
        -X POST http://www.openligadb.de/Webservices/Sportsdata.asmx" | getline line
  print "SOAP: ",line;
}
function soapGetMatchDataByGroupLeagueSaison(groupid, league, saison) {
  while ("less getMatchDataByGroupLeagueSaison.soap" | getline line) {
    sub(/[<groupOrderID>]=groupOrderID=[^<]*/, ">"groupid, line);
    sub(/[<leagueShortcut>]=leagueShortcut=[^<]*/, ">"league, line);
    sub(/[<leagueSaison>]=leagueSaison=[^<]*/, ">"saison, line);
    soap_msg = soap_msg line;
  }
  curl = "curl -H \"Content-Type: text/xml; charset=utf-8\" \
  	-H \"SOAPAction:\" \
  	-d '" soap_msg "' \
  	-X POST http://www.openligadb.de/Webservices/Sportsdata.asmx";
  curl | getline line;
  return line;
}
function soapGetMatchDataByTeams(team1, team2) {
  while ("less getMatchDataByTeams.soap" | getline line) {
    sub(/[<teamID1>]=teamID1=[^<]*/, ">"team1, line);
    sub(/[<teamID2>]=teamID2=[^<]*/, ">"team2, line);
    soap_msg = soap_msg line;
  }
  curl = "curl -H \"Content-Type: text/xml; charset=utf-8\" \
  		-H \"SOAPAction:\" \
	  	-d '"soap_msg"' \
	  	-X POST http://www.openligadb.de/Webservices/Sportsdata.asmx";
  curl | getline line;
  return line;
}
function getGames() {
  if (LIVE_PLAY==0) {
    # testing 
    # "curl -sL 'http://botliga.de/api/matches/2011' > kicktipp_2011.json"
    # "curl -sL 'http://botliga.de/api/matches/2010'" | getline ligaGames
    "less kicktipp_2011.json" | getline ligaGames
  } else {
    "curl -sL 'http://botliga.de/api/matches/2011'" | getline ligaGames
  }
}
function tipGames() {
  gamesTipCounter = 0;
  while (match(ligaGames, /{|}/)) {
    subLine = substr(ligaGames,0, RSTART + RLENGTH-2); 
    next_start_point = RSTART + RLENGTH;
    match(subLine,/"id":"[^"]*"/, matchid); 
    match(subLine,/"hostName":"[^"]*"/, hostname); 
    match(subLine,/"hostId":[^,]*/, hostid); 
    match(subLine,/"hostGoals":[^,]*/, hostgoals); 
    match(subLine,/"guestName":"[^"]*"/, guestname); 
    match(subLine,/"guestId":[^,]*/, guestid); 
    match(subLine,/"guestGoals":[^,]*/, guestgoals); 
    match(subLine,/"group":[^,]*/, group);
    match(subLine,/"date":"[^"]*"/, datetime);
    date = substr(splitValue(datetime[0]),1,10);
    if(LIVE_PLAY==0 || (LIVE_PLAY==1 && date == strftime("%Y-%m-%d"))) {
      if (length(splitValue(matchid[0])) > 0 && (LIVE_PLAY==1 || (LIVE_PLAY==0 && splitValue(matchid[0])==OUTPUT_MATCH_ID))) {
        mid = splitValue(matchid[0]);
        hid = splitIntValue(hostid[0]);
        gid = splitIntValue(guestid[0]);
        getMatchData(mid, hid, gid);
        hgoals = calHostGoals(mid);
        ggoals = calGuestGoals(mid); 
        matchValues = mid ":" hgoals ":" ggoals;
        matches[gamesTipCounter] = matchValues; 
        gamesTipCounter++;
      }
    }
    ligaGames = substr(ligaGames, next_start_point);
  }
}
function splitValue(m) {
  match(m,/"(.*)":"(.*)"/, values);
  return values[2];
}
function splitIntValue(m) {
  match(m,/"(.*)":(.*)/, values);
  return values[2];
}
function sendToBotLiga() {
  print "START  Anz.:" gamesTipCounter " " strftime("%Y-%m-%d %H:%m");
  if (gamesTipCounter>0) { 
    maxPosts = MAX_POST_MATCHES == -1 ? gamesTipCounter : MAX_POST_MATCHES;
    for (i=1;i<=maxPosts; i++) {
      split(matches[i-1],array,":");
      sendTip = "curl -X POST --data \""
      sendTip = sendTip "match_id=" array[1]
      sendTip = sendTip "&token=ewy5myxscuu9etps6vvo73x1"
      sendTip = sendTip "&result=" array[2] ":" array[3];
      sendTip = sendTip "\" "
      sendTip = sendTip "http://botliga.de/api/guess"
      if(LIVE_PLAY==1) {
        system(sendTip);
      }
      print sendTip >> "tipp.log";
    }
    print "++++ " strftime("%Y-%m-%d %H:%m") >> "tipp.log";
  }
}


