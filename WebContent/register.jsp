<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>注册</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="style.css">
</head>
<body class="center-body">
    <div class="auth-card" style="border-top: 4px solid var(--primary-color);">
        <h2 style="color:#333; margin-bottom:5px;">加入我们</h2>
        <p style="color:red; font-size:0.9rem;">${error}</p>
        <form action="register" method="post">
            <input type="text" name="username" class="form-control" placeholder="用户名" required>
            <input type="password" name="password" class="form-control" placeholder="密码" required>
            <button type="submit" class="btn btn-primary" style="width:100%">注册</button>
        </form>
        <div style="margin-top:20px; font-size:0.9rem;">
            <a href="login.jsp" style="color:var(--primary-color);">去登录</a> | <a href="items">返回首页</a>
        </div>
    </div>
</body>
</html>