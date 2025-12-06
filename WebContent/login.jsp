<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>登录</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="style.css">
</head>
<body class="center-body">
    <div class="auth-card">
        <h2 style="color:var(--primary-color); margin-bottom:10px;">账号登录</h2>
        <p style="color:red; font-size:0.9rem;">${error}</p>
        <p style="color:green; font-size:0.9rem;">${param.msg == 'success' ? '注册成功' : ''}</p>
        <form action="login" method="post">
            <input type="text" name="username" class="form-control" placeholder="用户名" required>
            <input type="password" name="password" class="form-control" placeholder="密码" required>
            <button type="submit" class="btn btn-primary" style="width:100%">登录</button>
        </form>
        <div style="margin-top:20px; font-size:0.9rem;">
            <a href="register.jsp" style="color:var(--primary-color);">注册账号</a> | <a href="items">游客访问</a>
        </div>
    </div>
</body>
</html>