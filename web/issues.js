(function(){
  var API="https://api.github.com/repos/mwridgway/sports-team-trumps/issues?state=open&per_page=30";
  var ALL="https://github.com/mwridgway/sports-team-trumps/issues";
  var status=document.getElementById("issues-status");
  var list=document.getElementById("issues-list");
  if(!status||!list)return;

  function fail(){
    status.textContent="";
    status.appendChild(document.createTextNode("We could not load the list. GitHub may be busy or has limited requests. "));
    var a=document.createElement("a");a.href=ALL;a.textContent="View all issues on GitHub";
    status.appendChild(a);status.appendChild(document.createTextNode("."));
  }
  function ago(iso){
    var d=Math.floor((Date.now()-new Date(iso).getTime())/864e5);
    if(d<=0)return "today";
    return d===1?"1 day ago":d+" days ago";
  }
  function render(items){
    var issues=items.filter(function(i){return !("pull_request" in i)});
    if(!issues.length){status.textContent="No open issues right now.";return;}
    status.textContent="";
    issues.forEach(function(i){
      var li=document.createElement("li");
      var a=document.createElement("a");a.className="issue";a.href=i.html_url;
      var t=document.createElement("span");t.className="issue-title";t.textContent=i.title;
      var m=document.createElement("span");m.className="issue-meta";
      var n=document.createElement("span");n.textContent="#"+i.number;m.appendChild(n);
      (i.labels||[]).forEach(function(l){
        var c=document.createElement("span");c.className="chip";c.textContent=typeof l==="string"?l:l.name;m.appendChild(c);
      });
      var u=document.createElement("span");u.textContent="updated "+ago(i.updated_at);m.appendChild(u);
      a.appendChild(t);a.appendChild(m);li.appendChild(a);list.appendChild(li);
    });
  }
  fetch(API,{headers:{Accept:"application/vnd.github+json"}})
    .then(function(r){if(!r.ok)throw new Error(r.status);return r.json();})
    .then(function(d){if(!Array.isArray(d))throw new Error("shape");render(d);})
    .catch(fail);
})();
