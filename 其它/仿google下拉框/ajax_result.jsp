<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%@ page import="com.giftcard.gift.service.GiftManager" %>
<%@ page import="cn.com.opendata.platform.Platform" %>
<%@ page import="java.util.List" %>
<%@ page import="com.giftcard.gift.model.Gift" %>
<%
	String keyword = request.getParameter("keyword");
%>
<ul>

	<li onclick="javascript:form_submit2('test');hide_suggest();">
		test
	</li>
</ul>