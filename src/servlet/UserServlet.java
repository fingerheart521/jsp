package servlet;

import dao.UserDAO;
import model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet({"/login", "/register", "/logout", "/users", "/delete_user"})
public class UserServlet extends HttpServlet {
    private UserDAO userDAO = new UserDAO();

    private boolean isAdmin(HttpServletRequest req) {
        User u = (User) req.getSession().getAttribute("currentUser");
        return u != null && "admin".equals(u.getRole());
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String uri = req.getRequestURI();

        if (uri.endsWith("register")) {
            User u = new User(req.getParameter("username"), req.getParameter("password"));
            if (userDAO.register(u)) {
                resp.sendRedirect("login.jsp?msg=success");
            } else {
                req.setAttribute("error", "用户已存在");
                req.getRequestDispatcher("register.jsp").forward(req, resp);
            }
        } else if (uri.endsWith("login")) {
            User u = userDAO.login(req.getParameter("username"), req.getParameter("password"));
            if (u != null) {
                req.getSession().setAttribute("currentUser", u);
                resp.sendRedirect("items");
            } else {
                req.setAttribute("error", "账号密码错误");
                req.getRequestDispatcher("login.jsp").forward(req, resp);
            }
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String uri = req.getRequestURI();

        if (uri.endsWith("logout")) {
            req.getSession().invalidate();
            resp.sendRedirect("items");
        } else if (uri.endsWith("users")) {
            if (!isAdmin(req)) {
                resp.sendRedirect("login.jsp");
                return;
            }
            req.setAttribute("users", userDAO.getAllUsers());
            req.getRequestDispatcher("users.jsp").forward(req, resp);
        } else if (uri.endsWith("delete_user")) {
            if (!isAdmin(req)) {
                resp.sendRedirect("login.jsp");
                return;
            }
            userDAO.deleteUser(Integer.parseInt(req.getParameter("id")));
            resp.sendRedirect("users");
        }
    }
}