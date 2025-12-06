<%@ page import="model.User" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="style.css">
</head>
<header class="header">
    <div class="header-inner">
        <div class="logo">校园失物招领平台</div>
        <nav class="nav-links">
            <% User headerUser = (User) session.getAttribute("currentUser");
               if(headerUser == null) { %>
                 <a href="login.jsp">登录</a>
                 <a href="register.jsp">注册</a>
            <% } else { %>
                 <span>你好, <%=headerUser.getUsername()%></span>
                 <% if("admin".equals(headerUser.getRole())) { %> 
                    <a href="users" style="color:#ffcc80">[管理]</a> 
                 <% } %>
                 <a href="add_item.jsp">发布</a>
                 <a href="logout">退出</a>
            <% } %>
        </nav>
    </div>
</header>