if (window.location.href.replaceAll(window.location.origin, '').replaceAll('/','').length === 0 ||
window.location.href.replaceAll(window.location.origin, '').replaceAll('/','') == '?locale=en') {

    window.onload = init;
    function init() {
        arrow = document.getElementById('arrow-left');
        text = document.getElementById('tooltip-box');

        etds = document.getElementById('etds');
        journals = document.getElementById('journals');
        articles = document.getElementById('articles');
        posters = document.getElementById('posters');
        presentations = document.getElementById('presentations');
        materials = document.getElementById('materials');

        etds.addEventListener("mouseover", (event) => {
            arrow.style.marginTop = '0';
            text.innerHTML = 'Browse theses and dissertations by GW students';
        });
        journals.addEventListener("mouseover", (event) => {
            arrow.style.marginTop = '2.7em';
            text.innerHTML = 'Browse journals published by GW student organizations and other GW-affiliated organizations';
        });
        articles.addEventListener("mouseover", (event) => {
            arrow.style.marginTop = '5.5em';
            text.innerHTML = 'Browse individual articles authored by GW faculty, staff, students, and published by GW-affiliated orgnaizations';
        });
        posters.addEventListener("mouseover", (event) => {
            arrow.style.marginTop = '8.2em';
            text.innerHTML = 'Browse posters created by GW faculty, staff, and students for various research purposes';
        });
        presentations.addEventListener("mouseover", (event) => {
            arrow.style.marginTop = '10.9em';
            text.innerHTML = 'Browse presentations given by GW faculty, staff, and students for conferences and other meetings';
        });
        materials.addEventListener("mouseover", (event) => {
            arrow.style.marginTop = '13.6em';
            text.innerHTML = 'Browse digitized and born-digital content from the specialized collections of GW Libraries & Academic Innovation';
        });
    }
}