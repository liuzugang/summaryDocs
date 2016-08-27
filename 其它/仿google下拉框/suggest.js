
var j = -1;
var temp_str;
var $ = function (node) {
	return document.getElementById(node);
};
var $$ = function (node) {
	return document.getElementsByTagName(node);
};
function ajax_keyword() {
	var xmlhttp;
	try {
		xmlhttp = new XMLHttpRequest();
	}catch (e) {
		xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
	}
	xmlhttp.onreadystatechange = function () {
		if (xmlhttp.readyState == 4) {
			if (xmlhttp.status == 200) {
				var data = xmlhttp.responseText;
				$("suggest").innerHTML = data;
				j = -1;
			}
		}
	};
	var key = document.getElementById("keyword").value;
	xmlhttp.open("post", "ajax_result.jsp", true);
	xmlhttp.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
	xmlhttp.send("keyword=" +key );
}

//*处理keyup函数*/
function keyupdeal(e) {
	var keyc;
	
	//*得到键盘值*/
	if (window.event) {//*如果是IE*/
		keyc = e.keyCode;
	} else {
		if (e.which) {//*如果是火狐*/
			keyc = e.which;
		}
	}
	if (keyc != 40 && keyc != 38) {//*如果不是方向键的“上，下”*/
		ajax_keyword();
		temp_str = $("keyword").value;
	}
}

//*设置被选中元素的样式*/
function set_style(num) {
	for (var i = 0; i < $$("li").length; i++) {
		var li_node = $$("li")[i];
		li_node.className = "";
	}
	if (j >= 0 && j < $$("li").length) {
		var i_node = $$("li")[j];
		$$("li")[j].className = "select";
	}
}

function form_submit2(keyword) {
	document.getElementById('keyword').value=keyword;
}

//*处理keydown事件*/
function keydowndeal(e) {
	var keyc;
	if (window.event) {
		keyc = e.keyCode;
	} else {
		if (e.which) {
			keyc = e.which;
		}
	}
	
	//*如果是方向键的“上，下”*/
	if (keyc == 40 || keyc == 38) {
		//*如果是方向键的“下”*/
		if (keyc == 40) {
		//alert(j+":"+$$("li").length); //-1  6
			if (j < $$("li").length) {
				j++;
				if (j >= $$("li").length) {
					j = -1;
				}
			}
			if (j >= $$("li").length) {
				j = -1;
			}
		}
		//*如果是方向键的“上”*/
		if (keyc == 38) {
			if (j >= 0) {
				j--;
				if (j <= -1) {
					j = $$("li").length;
				}
			} else {
				j = $$("li").length - 1;
			}
		}
		set_style(j);
		if (j >= 0 && j < $$("li").length) {
			$("keyword").value = $$("li")[j].childNodes[0].nodeValue;
		} else {
			$("keyword").value = temp_str;
		}
	}
}
function hide_suggest() {
	var nodes = document.body.childNodes;
	for (var i = 0; i < nodes.length; i++) {
		if (nodes[i] != $("keyword")) {
			$("suggest").innerHTML = "";
		}
	}
}
/**
function mo(nodevalue) {
	j = nodevalue;
	set_style(j);
}
function form_submit() {
	if (j >= 0 && j < $$("li").length) {
		$$("input")[0].value = $$("li")[j].childNodes[0].nodeValue;
	}
	document.search.submit();
}**/

