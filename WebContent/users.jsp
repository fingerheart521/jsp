<%@ page import="model.User, java.util.List" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>后台管理</title>
    </head>
<body>
    <%@ include file="header.jsp" %>
    
    <div class="container" style="background:white; margin-top:30px; border-radius:8px; padding:30px;">
        <h2>用户列表 <a href="items" style="float:right; font-size:1rem; color:#666; font-weight:normal;">返回首页</a></h2>
        
        <div class="admin-table-container">
            <table>
                <tr><th>ID</th><th>用户名</th><th>角色</th><th>操作</th></tr>
                <% List<User> users = (List<User>) request.getAttribute("users");
                   if(users!=null) for(User u : users) { %>
                <tr>
                    <td><%=u.getId()%></td>
                    <td><%=u.getUsername()%></td>
                    <td><%=u.getRole()%></td>
                    <td>
                        <% if(!"admin".equals(u.getRole())) { %>
                        <a href="delete_user?id=<%=u.getId()%>" style="color:red;" onclick="return confirm('确定删除？')">删除</a>
                        <% } else { %> - <% } %>
                    </td>
                </tr>
                <% } %>
            </table>
        </div>
    </div>
</body>
</html>