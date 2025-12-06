<%@ page import="model.*, java.util.List" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head><title>首页 - 校园失物招领</title></head>
<body>
    <%@ include file="header.jsp" %>

    <section class="hero-banner">
        <h1>拾金不昧 · 互助共享</h1>
        <p>共建和谐诚信校园环境</p>
    </section>

    <div class="container">
        <form action="items" method="get" style="text-align:center; margin-bottom:30px;">
            <input type="text" name="q" placeholder="搜索物品..." style="padding:10px; width:60%; border:1px solid #ddd; border-radius:4px;">
            <button type="submit" class="btn btn-primary">搜索</button>
        </form>

        <div style="display:grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap:20px;">
            <% List<Item> list = (List<Item>) request.getAttribute("itemList");
               if(list != null && !list.isEmpty()) {
                   for(Item i : list) {
                     String cls = "lost".equals(i.getType()) ? "lost" : "found";
                     String tag = "lost".equals(i.getType()) ? "寻物" : "招领"; %>
            <div class="card">
                <div style="display:flex; justify-content:space-between; margin-bottom:10px;">
                    <span class="tag <%=cls%>"><%=tag%></span>
                    <small style="color:#999"><%=i.getCreateTime().toString().substring(0,10)%></small>
                </div>
                <h3><a href="item_detail?id=<%=i.getId()%>" style="font-weight:bold;"><%=i.getTitle()%></a></h3>
                <p style="color:#666; margin:10px 0; font-size:0.9rem;" class="card-desc"><%=i.getDescription()%></p>
                <div style="font-size:0.85rem; color:#888;">
                    发布人：<%=i.getUsername()%>
                </div>
            </div>
            <% } } else { %>
                <p style="text-align:center; color:#999; grid-column:1/-1;">暂无数据</p>
            <% } %>
        </div>
    </div>
    <footer style="text-align:center; padding:30px; color:#999;">&copy; 2025 校园失物招领平台</footer>
</body>
</html>