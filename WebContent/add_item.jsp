<%@ page import="model.User" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    User user = (User) session.getAttribute("currentUser");
    if (user == null) { response.sendRedirect("login.jsp"); return; }
%>
<!DOCTYPE html>
<html>
<head><title>发布信息</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="style.css"> </head>
<body>
    <header class="header">
        <div class="header-inner">
            <div class="logo">发布中心</div>
            <div class="nav-links"><a href="items">返回首页</a></div>
        </div>
    </header>
    <div class="container">
        <div style="background:white; padding:40px; border-radius:8px; max-width:600px; width:100%; margin:30px auto; border-top:4px solid var(--primary-color); box-shadow:0 4px 15px rgba(0,0,0,0.05);">
            <h2 style="text-align:center; margin-bottom:10px;">发布信息</h2>
            <p style="text-align:center; color:#999; font-size:0.9rem; margin-bottom:30px;">详细描述特征，传递诚意与希望</p>
            
            <form action="publish" method="post" onsubmit="return document.getElementById('chk').checked">
                <label class="form-label" style="font-weight:bold; display:block; margin-bottom:5px;">标题</label>
                <input type="text" name="title" class="form-control" placeholder="例如：在二教捡到书" required>
                
                <label class="form-label" style="font-weight:bold; display:block; margin-bottom:5px;">类型</label>
                <select name="type" class="form-control">
                    <option value="lost">🔍 寻物启事</option>
                    <option value="found">📢 失物招领</option>
                </select>
                
                <label class="form-label" style="font-weight:bold; display:block; margin-bottom:5px;">描述</label>
                <textarea name="description" class="form-control" rows="6" 
                          placeholder="请详细描述物品外观、时间地点等。&#10;温馨提示：请确保信息真实。" required></textarea>
                
                <label class="form-label" style="font-weight:bold; display:block; margin-bottom:5px;">联系方式</label>
                <input type="text" name="contact" class="form-control" placeholder="QQ/微信/手机" required>
                
                <div style="margin-bottom:25px; background:#fff8e1; padding:15px; border:1px solid #ffecb3; font-size:0.9rem; border-radius:4px;">
                    <input type="checkbox" id="chk" required> <span><strong>诚信承诺：</strong>保证信息真实有效。</span>
                </div>
                <button type="submit" class="btn btn-primary" style="width:100%;">立即发布</button>
            </form>
        </div>
    </div>
</body>
</html>