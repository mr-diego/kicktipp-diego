function calHostGoals(hostid, guestid) {
  x=int(rand()*3 + 0.5);
  return "" x
}
function calGuestGoals(hostid, guestid) {
  x=int(rand()*2 + 0.5);
  return "" x;
}
function splitValue(m) {
  match(m,/"(.*)":"(.*)"/, values);
  return values[2];
}
BEGIN {
  MAX_POST_MATCHES = 9;
  LIVE_PLAY = 0; 
  if (LIVE_PLAY==0) {
    # testing without internet connection. Get the file with curl.
    # "curl -sL 'http://botliga.de/api/matches/2011' > kicktipp_2011.json"
    # "less kicktipp_2011.json" | getline line
    "curl -sL 'http://botliga.de/api/matches/2010'" | getline line
  } else {
    "curl -sL 'http://botliga.de/api/matches/2011'" | getline line
  }
  counter = 0;
  while (match(line, /{|}/)) {
    subLine = substr(line,0, RSTART + RLENGTH-2); 
    next_start_point = RSTART + RLENGTH;
    match(subLine,/"id":"[^"]*"/, matchid); 
    match(subLine,/"hostName":"[^"]*"/, hostname); 
    match(subLine,/"hostId":"[^"]*"/, hostid); 
    match(subLine,/"hostGoals":"[^"]*"/, hostgoals); 
    match(subLine,/"guestName":"[^"]*"/, guestName); 
    match(subLine,/"guestId":"[^"]*"/, guestid); 
    match(subLine,/"guestGoals":"[^"]*"/, guestgoals); 
    match(subLine,/"group":"[^"]*"/, group);
    match(subLine,/"date":"[^"]*"/, datetime);
    date = substr(splitValue(datetime[0]),1,10);
    if(LIVE_PLAY==0 || (LIVE_PLAY==1 && date == strftime("%Y-%m-%d"))) {
      if (length(splitValue(matchid[0])) > 0) {
        hid = splitValue(hostid[0]);
        gid = splitValue(guestid[0]);
        hgoals = calHostGoals(hid, gid);
        ggoals = calGuestGoals(hid, gid); 
        matchValues = splitValue(matchid[0]) ":" hgoals ":" ggoals;
        matches[counter] = matchValues; 
        counter++;
      }
    }
    line = substr(line, next_start_point);
  }
  if (counter>0) {
    for (i=1;i<=MAX_POST_MATCHES; i++) {
      split(matches[i-1],array,":");
      sendTip = "curl -X POST --data \""
      sendTip = sendTip "match_id=" array[1]
      sendTip = sendTip "&token=ewy5myxscuu9etps6vvo73x1"
      sendTip = sendTip "&result=" array[2] ":" array[3];
      sendTip = sendTip "\" "
      sendTip = sendTip "http://botliga.de/api/guess"
      if(LIVE_PLAY==0) {
         #system(sendTip);
         print sendTip;
      } else {
        system(sendTip);
      }
    }
  }
  print "DONE!";
}
