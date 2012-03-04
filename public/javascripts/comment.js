	function setbg(color)
	{
		document.getElementById("comment_content").style.background=color;
	}
	function show_comment_form(){
		document.getElementById("comment_form").style.display="block";
		document.getElementById("comment_content").focus();
	}

	function hide_comment_form(){
		document.getElementById("comment_form").style.display="none";
	}