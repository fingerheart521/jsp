package dao;

import model.Comment;
import util.DBUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CommentDAO {

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