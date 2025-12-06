package servlet;

import dao.CommentDAO;
import dao.ItemDAO;
import model.Item;
import model.Comment;
import model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet({"/items", "/item_detail", "/publish", "/delete_item", "/post_comment", "/delete_comment"})
public class PostServlet extends HttpServlet {
    private ItemDAO itemDAO = new ItemDAO();
    private CommentDAO commentDAO = new CommentDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String uri = req.getRequestURI();
        User user = (User) req.getSession().getAttribute("currentUser");

        if (uri.endsWith("item_detail")) {
            String idStr = req.getParameter("id");
            if (idStr == null) {
                resp.sendRedirect("items");
                return;
            }
            int id = Integer.parseInt(idStr);
            req.setAttribute("item", itemDAO.getItemById(id));
            req.setAttribute("comments", commentDAO.getCommentsByItemId(id));
            req.getRequestDispatcher("detail.jsp").forward(req, resp);

        } else if (uri.endsWith("delete_item")) {
            String idStr = req.getParameter("id");
            if (user != null && idStr != null) {
                int itemId = Integer.parseInt(idStr);
                Item item = itemDAO.getItemById(itemId);
                if (item != null && (user.getId() == item.getUserId() || "admin".equals(user.getRole()))) {
                    itemDAO.deleteItem(itemId);
                }
            }
            resp.sendRedirect("items");

        } else if (uri.endsWith("delete_comment")) {
            String idStr = req.getParameter("id");
            String itemIdStr = req.getParameter("itemId");
            if (user != null && idStr != null) {
                int commentId = Integer.parseInt(idStr);
                Comment comment = commentDAO.getCommentById(commentId);
                if (comment != null && (user.getId() == comment.getUserId() || "admin".equals(user.getRole()))) {
                    commentDAO.deleteComment(commentId);
                }
            }
            resp.sendRedirect("item_detail?id=" + itemIdStr);

        } else {
            String q = req.getParameter("q");
            req.setAttribute("itemList", itemDAO.searchItems(q == null ? "" : q));
            req.getRequestDispatcher("index.jsp").forward(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        String uri = req.getRequestURI();

        if (uri.endsWith("publish")) {
            Item item = new Item(req.getParameter("title"), req.getParameter("description"),
                    req.getParameter("type"), req.getParameter("contact"));
            item.setUserId(user.getId());
            itemDAO.addItem(item);
            resp.sendRedirect("items");

        } else if (uri.endsWith("post_comment")) {
            Comment c = new Comment();
            c.setItemId(Integer.parseInt(req.getParameter("itemId")));
            c.setUserId(user.getId());
            c.setContent(req.getParameter("content"));
            commentDAO.addComment(c);
            resp.sendRedirect("item_detail?id=" + c.getItemId());
        }
    }
}