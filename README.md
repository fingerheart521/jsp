# JSP期末大作业——校园失物招领平台

食用说明文档

**组长：刘道广**

**组员：钊祥、张昱璐**



## 目录

[TOC]



## 1、环境配置

Eclipse IDE：2018-09 (4.9.0)

mysql：community-8.0.44.0

tomcat：apache-tomcat-8.5.38

jdk：1.8.0_461



### mysql建表语句

首次配置项目请务必建表（全部复制粘贴即可）

```mysql
-- 1. 创建数据库 (如果不存在) 并指定字符集为 utf8mb4 (支持中文)
CREATE DATABASE IF NOT EXISTS lost_found_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 2. 切换到该数据库
USE lost_found_db;

-- ==========================================
-- 3. 创建用户表 (users)
-- ==========================================
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
    password VARCHAR(50) NOT NULL COMMENT '密码',
    role VARCHAR(10) DEFAULT 'user' COMMENT '角色: admin 或 user'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==========================================
-- 4. 创建物品表 (items)
-- ==========================================
CREATE TABLE IF NOT EXISTS items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL COMMENT '发布人ID',
    title VARCHAR(100) NOT NULL COMMENT '标题',
    description TEXT COMMENT '详细描述',
    type VARCHAR(10) NOT NULL COMMENT '类型: lost 或 found',
    contact VARCHAR(50) COMMENT '联系方式',
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
    -- 外键约束：当用户被删除时，发布的物品也一并删除
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==========================================
-- 5. 创建评论表 (comments)
-- ==========================================
CREATE TABLE IF NOT EXISTS comments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    item_id INT NOT NULL COMMENT '关联物品ID',
    user_id INT NOT NULL COMMENT '评论人ID',
    content TEXT NOT NULL COMMENT '评论内容',
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '评论时间',
    -- 外键约束：物品或用户删除时，相关评论也删除
    FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==========================================
-- 6. 初始化测试数据
-- ==========================================

-- 插入管理员账号 (用户名: admin, 密码: 123)
INSERT INTO users (username, password, role) VALUES ('admin', '123', 'admin');

-- 插入一个普通测试用户 (用户名: test, 密码: 123)
INSERT INTO users (username, password, role) VALUES ('test', '123', 'user');

-- 插入一条测试物品信息 (由 test 用户发布)
INSERT INTO items (user_id, title, description, type, contact) 
VALUES (2, '在图书馆捡到一个水杯', '蓝色，膳魔师牌子，放在2楼阅览室桌子上了。', 'found', 'QQ: 123456');

-- 插入一条测试评论 (由 admin 用户评论)
INSERT INTO comments (item_id, user_id, content) 
VALUES (1, 1, '同学你好，那个水杯可能是我的，方便联系吗？');

-- 提交事务
COMMIT;
```



## 2、文件配置

文件目录树如下

```tex
LostFoundSystem/
├── src/
│   ├── dao/             <-- 数据访问层
│   │   ├── CommentDAO.java
│   │   ├── ItemDAO.java
│   │   └── UserDAO.java
│   ├── model/           <-- 实体类
│   │   ├── Comment.java
│   │   ├── Item.java
│   │   └── User.java
│   ├── servlet/         <-- 控制层
│   │   ├── PostServlet.java  (处理物品+评论)
│   │   └── UserServlet.java  (处理登录+注册+管理)
│   └── util/            <-- 工具类
│       └── DBUtil.java
│
└── WebContent/          <-- 网页根目录
    ├── WEB-INF/
    │   └── lib/         <-- 放入 mysql-connector-java.jar
    ├── add_item.jsp
    ├── detail.jsp
    ├── header.jsp       <-- 公共头部
    ├── index.jsp
    ├── login.jsp
    ├── register.jsp
    ├── style.css        <-- 样式表
    └── users.jsp        <-- 后台管理页
```



## 3、代码配置

### 1. Java Model (实体类)

#### User.java

```java
package model;

/**
 * 用户实体类 (JavaBean)
 * 对应数据库表: users
 * 作用: 负责在各层之间传递用户信息数据
 */
public class User {
    // 对应数据库的主键 ID
    private int id;
    // 用户名 (唯一标识)
    private String username;
    // 密码 (实际生产中应存储加密后的哈希值，此处演示用明文)
    private String password;
    // 角色权限: "admin" (管理员) 或 "user" (普通用户)
    private String role; 

    // 无参构造器 (JavaBean 规范必须提供)
    public User() {}

    // 全参构造器 (方便快速创建对象)
    public User(String username, String password) {
        this.username = username;
        this.password = password;
        this.role = "user"; // 默认注册的角色都是普通用户
    }

    // --- 标准 Getter 和 Setter 方法 ---
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
}
```

#### Item.java

```java
package model;
import java.util.Date;

/**
 * 物品实体类 (失物/招领信息)
 * 对应数据库表: items
 */
public class Item {
    private int id;             // 物品ID
    private int userId;         // 发布该物品的用户ID (外键)
    private String title;       // 标题
    private String description; // 详细描述
    private String type;        // 类型标识: "lost"(寻物) 或 "found"(招领)
    private String contact;     // 联系方式
    private Date createTime;    // 发布时间
    
    // 这是一个非数据库原生字段 (DTO特性)
    // 数据库 items 表只存了 user_id，但在页面展示时我们需要显示人名
    // 所以这里增加一个属性，用于暂存连表查询出来的用户名
    private String username;

    public Item() {}

    public Item(String title, String description, String type, String contact) {
        this.title = title;
        this.description = description;
        this.type = type;
        this.contact = contact;
    }

    // --- Getters 和 Setters ---
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getContact() { return contact; }
    public void setContact(String contact) { this.contact = contact; }
    public Date getCreateTime() { return createTime; }
    public void setCreateTime(Date createTime) { this.createTime = createTime; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
}
```

#### Comment.java

```java
package model;
import java.util.Date;

/**
 * 评论实体类
 * 对应数据库表: comments
 */
public class Comment {
    private int id;
    private int itemId;         // 关联的物品ID (属于哪条帖子)
    private int userId;         // 关联的用户ID (是谁发的)
    private String content;     // 评论内容
    private Date createTime;    // 评论时间
    private String username;    // 辅助字段：用于显示评论人的名字

    public Comment() {}

    // --- Getters 和 Setters ---
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public int getItemId() { return itemId; }
    public void setItemId(int itemId) { this.itemId = itemId; }
    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public Date getCreateTime() { return createTime; }
    public void setCreateTime(Date createTime) { this.createTime = createTime; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
}
```



### 2. Java Util (工具类)

#### DBUtil.java

```java
package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * 数据库工具类 (Utility Class)
 * 作用: 封装数据库连接逻辑，提供统一的获取 Connection 接口
 */
public class DBUtil {
    
    // JDBC 连接字符串
    // useSSL=false: 关闭 SSL 警告
    // serverTimezone=UTC: 解决时区报错问题
    // characterEncoding=utf8: 防止中文乱码
    private static final String URL = "jdbc:mysql://localhost:3306/lost_found_db?useSSL=false&serverTimezone=UTC&characterEncoding=utf8&allowPublicKeyRetrieval=true";
    
    // 数据库账号
    private static final String USER = "root";
    // 数据库密码
    private static final String PASSWORD = "123456"; 

    // 静态代码块：类加载时执行一次
    // 作用：加载 MySQL 驱动程序到内存中
    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace(); // 如果找不到 jar 包，这里会报错
        }
    }

    /**
     * 获取数据库连接
     * @return Connection 对象
     * @throws SQLException 连接失败时抛出
     */
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}
```



### 3. Java DAO (数据访问层)

#### UserDAO.java

```java
package dao;

import model.User;
import util.DBUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 用户数据访问对象 (Data Access Object)
 * 作用: 封装所有与 users 表相关的 SQL 操作，屏蔽数据库细节
 */
public class UserDAO {

    /**
     * 用户注册
     * @param user 包含用户名和密码的对象
     * @return boolean 注册成功返回 true
     */
    public boolean register(User user) {
        String sql = "INSERT INTO users (username, password, role) VALUES (?, ?, ?)";
        // 使用 try-with-resources 自动关闭连接资源
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, user.getUsername());
            ps.setString(2, user.getPassword());
            ps.setString(3, "user"); // 新用户默认角色为普通用户
            
            // executeUpdate 返回受影响行数，>0 表示插入成功
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * 用户登录验证
     * @return 登录成功返回 User 对象，失败返回 null
     */
    public User login(String username, String password) {
        String sql = "SELECT * FROM users WHERE username=? AND password=?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, username);
            ps.setString(2, password);
            
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    // 查到数据，封装成对象返回
                    User u = new User();
                    u.setId(rs.getInt("id"));
                    u.setUsername(rs.getString("username"));
                    u.setPassword(rs.getString("password"));
                    u.setRole(rs.getString("role"));
                    return u;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null; // 账号或密码错误
    }

    /**
     * 获取所有用户列表 (后台管理用)
     */
    public List<User> getAllUsers() {
        List<User> list = new ArrayList<>();
        String sql = "SELECT * FROM users";
        try (Connection conn = DBUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                User u = new User();
                u.setId(rs.getInt("id"));
                u.setUsername(rs.getString("username"));
                u.setRole(rs.getString("role"));
                list.add(u);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * 根据ID删除用户 (后台管理用)
     */
    public void deleteUser(int id) {
        String sql = "DELETE FROM users WHERE id=?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
```

#### ItemDAO.java

```java
package dao;

import model.Item;
import util.DBUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 物品数据访问对象
 * 处理 items 表的增删改查
 */
public class ItemDAO {

    // 辅助方法: 将 ResultSet 的当前行数据映射到 Item 对象
    // 注意: 这里同时从结果集中取出了连表查询得到的 username
    private Item mapRow(ResultSet rs) throws SQLException {
        Item item = new Item();
        item.setId(rs.getInt("id"));
        item.setUserId(rs.getInt("user_id"));
        item.setTitle(rs.getString("title"));
        item.setDescription(rs.getString("description"));
        item.setType(rs.getString("type"));
        item.setContact(rs.getString("contact"));
        item.setCreateTime(rs.getTimestamp("create_time"));
        item.setUsername(rs.getString("username")); // 获取发布人昵称
        return item;
    }

    /**
     * 获取所有物品 (默认调用空字符串搜索)
     */
    public List<Item> getAllItems() {
        return searchItems("");
    }

    /**
     * 搜索物品 (支持连表查询)
     * 使用 JOIN 关键字关联 items 和 users 表，以便获取发布人名字
     */
    public List<Item> searchItems(String keyword) {
        List<Item> list = new ArrayList<>();
        // SQL: 查询物品表(i)和用户表(u)，条件是标题或描述包含关键词，按时间倒序
        String sql = "SELECT i.*, u.username FROM items i JOIN users u ON i.user_id = u.id " +
                     "WHERE i.title LIKE ? OR i.description LIKE ? ORDER BY i.create_time DESC";
        
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, "%" + keyword + "%"); // 模糊查询
            ps.setString(2, "%" + keyword + "%");
            
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * 根据ID获取单个物品详情
     */
    public Item getItemById(int id) {
        String sql = "SELECT i.*, u.username FROM items i JOIN users u ON i.user_id = u.id WHERE i.id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * 发布新物品
     */
    public void addItem(Item item) {
        String sql = "INSERT INTO items (title, description, type, contact, user_id) VALUES (?,?,?,?,?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, item.getTitle());
            ps.setString(2, item.getDescription());
            ps.setString(3, item.getType());
            ps.setString(4, item.getContact());
            ps.setInt(5, item.getUserId());
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    /**
     * 删除物品
     */
    public void deleteItem(int id) {
        String sql = "DELETE FROM items WHERE id=?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
```

#### CommentDAO.java

```java
package dao;

import model.Comment;
import util.DBUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 评论数据访问对象
 */
public class CommentDAO {

    /**
     * 获取某物品下的所有评论 (连表查询用户名)
     */
    public List<Comment> getCommentsByItemId(int itemId) {
        List<Comment> list = new ArrayList<>();
        String sql = "SELECT c.*, u.username FROM comments c JOIN users u ON c.user_id = u.id WHERE c.item_id = ? ORDER BY c.create_time DESC";
        
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, itemId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Comment c = new Comment();
                    c.setId(rs.getInt("id"));
                    c.setItemId(rs.getInt("item_id"));
                    c.setUserId(rs.getInt("user_id"));
                    c.setContent(rs.getString("content"));
                    c.setCreateTime(rs.getTimestamp("create_time"));
                    c.setUsername(rs.getString("username"));
                    list.add(c);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * 根据ID获取单条评论 (用于在删除前校验权限)
     */
    public Comment getCommentById(int id) {
        Comment c = null;
        String sql = "SELECT * FROM comments WHERE id=?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    c = new Comment();
                    c.setId(rs.getInt("id"));
                    c.setItemId(rs.getInt("item_id"));
                    c.setUserId(rs.getInt("user_id"));
                    c.setContent(rs.getString("content"));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return c;
    }

    /**
     * 发表评论
     */
    public void addComment(Comment c) {
        String sql = "INSERT INTO comments (item_id, user_id, content) VALUES (?,?,?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, c.getItemId());
            ps.setInt(2, c.getUserId());
            ps.setString(3, c.getContent());
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    /**
     * 删除评论
     */
    public void deleteComment(int id) {
        String sql = "DELETE FROM comments WHERE id=?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
```



### 4. Java Servlet (控制器层)

#### UserServlet.java

```java
package servlet;

import dao.UserDAO;
import model.User;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

/**
 * 用户模块控制器
 * 负责处理: 登录、注册、注销、后台用户管理
 * 映射路径包含: /login, /register, /logout, /users, /delete_user
 */
@WebServlet({"/login", "/register", "/logout", "/users", "/delete_user"})
public class UserServlet extends HttpServlet {
    private UserDAO userDAO = new UserDAO();

    // 辅助方法: 检查当前登录用户是否是管理员
    private boolean isAdmin(HttpServletRequest req) {
        User u = (User) req.getSession().getAttribute("currentUser");
        return u != null && "admin".equals(u.getRole());
    }

    /**
     * 处理 POST 请求 (通常用于表单提交)
     */
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8"); // 处理中文乱码
        String uri = req.getRequestURI(); // 获取请求路径

        if (uri.endsWith("register")) {
            // --- 注册逻辑 ---
            User u = new User(req.getParameter("username"), req.getParameter("password"));
            if (userDAO.register(u)) {
                // 注册成功，重定向到登录页
                resp.sendRedirect("login.jsp?msg=success");
            } else {
                // 注册失败，转发回注册页并显示错误
                req.setAttribute("error", "用户已存在");
                req.getRequestDispatcher("register.jsp").forward(req, resp);
            }
        } else if (uri.endsWith("login")) {
            // --- 登录逻辑 ---
            User u = userDAO.login(req.getParameter("username"), req.getParameter("password"));
            if (u != null) {
                // 登录成功，将用户信息存入 Session
                req.getSession().setAttribute("currentUser", u);
                resp.sendRedirect("items"); // 跳转首页
            } else {
                // 登录失败
                req.setAttribute("error", "账号密码错误");
                req.getRequestDispatcher("login.jsp").forward(req, resp);
            }
        }
    }

    /**
     * 处理 GET 请求 (页面跳转、查询、删除)
     */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String uri = req.getRequestURI();

        if (uri.endsWith("logout")) {
            // --- 注销 ---
            req.getSession().invalidate(); // 销毁会话
            resp.sendRedirect("items");
        } else if (uri.endsWith("users")) {
            // --- 后台: 查看用户列表 ---
            if (!isAdmin(req)) {
                resp.sendRedirect("login.jsp"); // 权限拦截
                return;
            }
            // 查询数据并存入 Request 域
            req.setAttribute("users", userDAO.getAllUsers());
            req.getRequestDispatcher("users.jsp").forward(req, resp);
        } else if (uri.endsWith("delete_user")) {
            // --- 后台: 删除用户 ---
            if (!isAdmin(req)) {
                resp.sendRedirect("login.jsp");
                return;
            }
            userDAO.deleteUser(Integer.parseInt(req.getParameter("id")));
            resp.sendRedirect("users"); // 删完刷新列表
        }
    }
}
```

#### PostServlet.java

```java
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

/**
 * 帖子/评论模块控制器
 * 负责处理: 首页列表、发布、详情、评论、删除等
 */
@WebServlet({"/items", "/item_detail", "/publish", "/delete_item", "/post_comment", "/delete_comment"})
public class PostServlet extends HttpServlet {
    private ItemDAO itemDAO = new ItemDAO();
    private CommentDAO commentDAO = new CommentDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String uri = req.getRequestURI();
        User user = (User) req.getSession().getAttribute("currentUser");

        if (uri.endsWith("item_detail")) {
            // --- 详情页 ---
            String idStr = req.getParameter("id");
            if (idStr == null) {
                resp.sendRedirect("items");
                return;
            }
            int id = Integer.parseInt(idStr);
            // 查询物品详情和该物品下的评论
            req.setAttribute("item", itemDAO.getItemById(id));
            req.setAttribute("comments", commentDAO.getCommentsByItemId(id));
            req.getRequestDispatcher("detail.jsp").forward(req, resp);

        } else if (uri.endsWith("delete_item")) {
            // --- 删除物品 ---
            String idStr = req.getParameter("id");
            if (user != null && idStr != null) {
                int itemId = Integer.parseInt(idStr);
                Item item = itemDAO.getItemById(itemId);
                // 权限校验: 只有发布者本人或管理员可以删除
                if (item != null && (user.getId() == item.getUserId() || "admin".equals(user.getRole()))) {
                    itemDAO.deleteItem(itemId);
                }
            }
            resp.sendRedirect("items");

        } else if (uri.endsWith("delete_comment")) {
            // --- 删除评论 ---
            String idStr = req.getParameter("id");
            String itemIdStr = req.getParameter("itemId"); // 这里的 itemId 是为了删完跳回详情页
            if (user != null && idStr != null) {
                int commentId = Integer.parseInt(idStr);
                Comment comment = commentDAO.getCommentById(commentId);
                // 权限校验
                if (comment != null && (user.getId() == comment.getUserId() || "admin".equals(user.getRole()))) {
                    commentDAO.deleteComment(commentId);
                }
            }
            resp.sendRedirect("item_detail?id=" + itemIdStr);

        } else {
            // --- 默认: 首页列表/搜索 ---
            String q = req.getParameter("q"); // 搜索关键词
            req.setAttribute("itemList", itemDAO.searchItems(q == null ? "" : q));
            req.getRequestDispatcher("index.jsp").forward(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        User user = (User) req.getSession().getAttribute("currentUser");
        
        // 任何发布操作都需要登录
        if (user == null) {
            resp.sendRedirect("login.jsp");
            return;
        }

        String uri = req.getRequestURI();

        if (uri.endsWith("publish")) {
            // --- 发布物品 ---
            Item item = new Item(req.getParameter("title"), req.getParameter("description"),
                    req.getParameter("type"), req.getParameter("contact"));
            item.setUserId(user.getId());
            itemDAO.addItem(item);
            resp.sendRedirect("items");

        } else if (uri.endsWith("post_comment")) {
            // --- 发表评论 ---
            Comment c = new Comment();
            c.setItemId(Integer.parseInt(req.getParameter("itemId")));
            c.setUserId(user.getId());
            c.setContent(req.getParameter("content"));
            commentDAO.addComment(c);
            resp.sendRedirect("item_detail?id=" + c.getItemId());
        }
    }
}
```



### 5. CSS 样式

#### style.css

```css
@charset "UTF-8";

/* === 全局变量定义 === */
:root {
    --primary-color: #C62828; /* 中国红 */
    --secondary-color: #FFD700; /* 荣耀金 */
    --text-dark: #333;
    --bg-light: #F9F9F9;
    --white: #FFFFFF;
    --radius: 8px; /* 圆角统一大小 */
}

/* === 基础重置 === */
* { margin:0; padding:0; box-sizing:border-box; }
body { font-family: sans-serif; background-color: var(--bg-light); color: var(--text-dark); line-height:1.6; }
a { text-decoration: none; color: inherit; transition:0.3s; }

/* === 顶部导航栏 === */
.header { background: var(--primary-color); color: white; padding: 0 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
.header-inner { max-width: 1000px; margin: 0 auto; height: 60px; display: flex; justify-content: space-between; align-items: center; }
.logo { font-weight: bold; font-size: 1.2rem; }
.nav-links a { margin-left: 20px; color: rgba(255,255,255,0.9); font-size:0.95rem; }
.nav-links a:hover { color: white; }

/* === 通用容器 === */
.container { max-width: 1000px; margin: 0 auto; padding: 20px; }

/* === 首页 Banner === */
.hero-banner { background: linear-gradient(135deg, #e53935 0%, #e35d5b 100%); color: white; text-align: center; padding: 40px 20px; margin-bottom: 30px; }

/* === 卡片样式 (首页) === */
.card { background: white; border-radius: var(--radius); padding: 15px; margin-bottom: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.05); border: 1px solid #eee; transition:0.3s; }
.card:hover { transform: translateY(-3px); box-shadow: 0 5px 15px rgba(0,0,0,0.1); }

/* === 标签样式 === */
.tag { font-size: 0.8rem; padding: 3px 8px; border-radius: 4px; font-weight: bold; }
.tag.lost { background: #ffebee; color: #c62828; border: 1px solid #ffcdd2; }
.tag.found { background: #e8f5e9; color: #2e7d32; border: 1px solid #c8e6c9; }

/* === 按钮与表单 === */
.btn { padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; }
.btn-primary { background: var(--primary-color); color: white; }
.form-control { width: 100%; padding: 10px; margin-bottom: 15px; border: 1px solid #ccc; border-radius: 4px; }

/* === 登录/注册/发布页容器 === */
/* 统一使用 auth-card 样式或类似的白盒样式 */
.auth-card { background: white; padding: 40px; border-radius: 8px; width: 380px; text-align: center; box-shadow: 0 4px 20px rgba(0,0,0,0.08); border-top: 4px solid var(--primary-color); }
.center-body { min-height: 100vh; display: flex; align-items: center; justify-content: center; }

/* === 文本截断处理 === */
.card h3 { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 100%; display: block; }
.card-desc { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.admin-table td { max-width: 150px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

/* === 响应式设计 (手机端适配) === */
@media screen and (max-width: 768px) {
    /* 导航栏变为垂直排列 */
    .header-inner { flex-direction: column; height: auto; padding: 10px 0; }
    .nav-links { flex-wrap: wrap; justify-content: center; gap: 10px; }
    
    /* 容器自适应宽度 */
    div[style*="width:600px"], 
    div[style*="width:380px"], 
    .auth-card { 
        width: 95% !important; 
        margin: 20px auto !important; 
        padding: 20px !important; 
    }
    
    /* 搜索框全宽 */
    form[action="items"] input[name="q"], 
    form[action="items"] button { 
        width: 100% !important; 
        margin-bottom: 10px; 
    }
    
    /* 后台表格横向滚动 */
    .admin-container { padding: 15px; overflow-x: auto; }
    table { min-width: 600px; }
}
```



### 6. JSP 页面 (含公共引用)

#### header.jsp (公共头部文件)

```jsp
<%@ page import="model.User" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="style.css"> </head>
<header class="header">
    <div class="header-inner">
        <div class="logo">校园失物招领</div>
        <nav class="nav-links">
            <% 
               // 获取当前登录用户
               User headerUser = (User) session.getAttribute("currentUser");
               if(headerUser == null) { 
            %>
                 <a href="login.jsp">登录</a>
                 <a href="register.jsp">注册</a>
            <% } else { %>
                 <span>你好, <%=headerUser.getUsername()%></span>
                 <% 
                    // 只有管理员才显示管理入口
                    if("admin".equals(headerUser.getRole())) { 
                 %> 
                    <a href="users" style="color:#ffcc80">[管理]</a> 
                 <% } %>
                 <a href="add_item.jsp">➕ 发布</a>
                 <a href="logout">退出</a>
            <% } %>
        </nav>
    </div>
</header>
```

#### index.jsp (首页)

```jsp
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
            <% 
               List<Item> list = (List<Item>) request.getAttribute("itemList");
               if(list != null && !list.isEmpty()) {
                   for(Item i : list) {
                     String cls = "lost".equals(i.getType()) ? "lost" : "found";
                     String tag = "lost".equals(i.getType()) ? "寻物" : "招领"; 
            %>
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
            <%     } 
               } else { %>
                <p style="text-align:center; color:#999; grid-column:1/-1;">暂无数据，请尝试发布或搜索。</p>
            <% } %>
        </div>
    </div>
    <footer style="text-align:center; padding:30px; color:#999;">&copy; 2025 校园失物招领平台</footer>
</body>
</html>
```

#### detail.jsp (详情页)

```jsp
<%@ page import="model.*, java.util.List" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head><title>详情</title></head>
<body>
    <%@ include file="header.jsp" %>
    <% User currentUser = (User) session.getAttribute("currentUser"); %>

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
            <%     } 
               } else { %>
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
```

#### add_item.jsp (发布页)

```jsp
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
<link rel="stylesheet" href="style.css">
</head>
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
```

#### login.jsp (登录页)

```jsp
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
```

#### register.jsp (注册页)

```jsp
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
```

#### users.jsp (后台用户管理)

```jsp
<%@ page import="model.User, java.util.List" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>后台管理</title>
    <link rel="stylesheet" href="style.css"> <style>
        table { width:100%; border-collapse:collapse; margin-top:20px; min-width:600px; }
        th { background:var(--primary-color); color:white; padding:10px; text-align:left; }
        td { padding:10px; border-bottom:1px solid #eee; }
        tr:hover { background:#f9f9f9; }
        .admin-table-container { overflow-x:auto; }
    </style>
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
```

