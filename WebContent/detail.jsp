<%@ page import="model.*, java.util.List" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head><title>详情</title></head>
<body>
    <%@ include file="header.jsp" %>
    <% 
        // 这里的 u 来自 header.jsp 的 session 获取，可以直接用
        User currentUser = (User) session.getAttribute("currentUser"); 
    %>

    <div class="container" style="margin-top:30px;">
        <% 
           Item item = (Item) request.getAttribute("item");
           boolean isAdmin = (currentUser != null && "admin".equals(currentUser.getRole()));
           boolean isOwner = (currentUser != null && item != null && currentUser.getId() == item.getUserId());

           if(item == null) {
               out.print("<p style='text-align:center'>物品不存在</p>");
           } else {
               String cls = "lost".equals(item.getType()) ? "lost" : "found";
               String tag = "lost".equals(item.getType()) ? "寻物启事" : "失物招领";
        %>
        
        <div style="background:white; padding:30px; border-radius:8px; box-shadow:0 2px 10px rgba(0,0,0,0.05);">
            <div style="border-bottom:1px solid #eee; padding-bottom:15px; margin-bottom:20px; display:flex; justify-content:space-between; align-items:center;">
                <div>
                    <span class="tag <%=cls%>" style="font-size:1rem; margin-right:10px;"><%=tag%></span>
                    <h1 style="display:inline; font-size:1.5rem;"><%=item.getTitle()%></h1>
                </div>
                <% if (isOwner || isAdmin) { %>
                    <a href="delete_item?id=<%=item.getId()%>" 
                       onclick="return confirm('确定要删除这条信息吗？')"
                       class="btn" style="background:#ffebee; color:#c62828; padding:5px 15px; font-size:0.9rem;">🗑️ 删除</a>
                <% } %>
            </div>
            
            <p><strong>发布人：</strong><%=item.getUsername()%> &nbsp;|&nbsp; <strong>时间：</strong><%=item.getCreateTime()%></p>
            <p style="margin-top:10px;"><strong>联系方式：</strong><span style="color:var(--primary-color); font-weight:bold;"><%=item.getContact()%></span></p>
            <div style="background:#f9f9f9; padding:20px; border-left:4px solid var(--secondary-color); margin:20px 0; border-radius:4px;">
                <%=item.getDescription()%>
            </div>
            <div style="background:#e3f2fd; color:#0d47a1; padding:15px; border-radius:4px; font-size:0.9rem;">
                🛡️ 安全提示：交易或归还请选择公共场所，谨防诈骗。
            </div>

            <h3 style="margin-top:40px; margin-bottom:20px;">💬 留言区</h3>
            
            <% List<Comment> comments = (List<Comment>) request.getAttribute("comments");
               if(comments != null && !comments.isEmpty()) {
                   for(Comment c : comments) { 
                       boolean isCommentOwner = (currentUser != null && currentUser.getId() == c.getUserId());
            %>
               <div style="border-bottom:1px dashed #eee; padding:15px 0;">
                   <div>
                       <strong style="margin-right:10px;"><%=c.getUsername()%></strong>
                       <span style="color:#999; font-size:0.85rem;"><%=c.getCreateTime()%></span>
                       <% if(isAdmin || isCommentOwner) { %>
                           <a href="delete_comment?id=<%=c.getId()%>&itemId=<%=item.getId()%>" 
                              style="color:red; font-size:0.8rem; margin-left:10px;"
                              onclick="return confirm('删除这条评论？')">[删除]</a>
                       <% } %>
                   </div>
                   <p style="margin-top:5px; color:#555;"><%=c.getContent()%></p>
               </div>
            <% } } else { %>
               <p style="color:#999;">暂无留言。</p>
            <% } %>

            <div style="margin-top:30px; background:#fafafa; padding:20px; border-radius:8px;">
                <% if(currentUser != null) { %>
                <form action="post_comment" method="post">
                    <input type="hidden" name="itemId" value="<%=item.getId()%>">
                    <textarea name="content" class="form-control" rows="3" placeholder="文明留言..." required></textarea>
                    <button type="submit" class="btn btn-primary">提交</button>
                </form>
                <% } else { %>
                    <p><a href="login.jsp" style="color:var(--primary-color);">登录</a> 后发表留言</p>
                <% } %>
            </div>
        </div>
        <% } %>
    </div>
</body>
</html>