package dao;

import model.Item;
import util.DBUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ItemDAO {

    private Item mapRow(ResultSet rs) throws SQLException {
        Item item = new Item();
        item.setId(rs.getInt("id"));
        item.setUserId(rs.getInt("user_id"));
        item.setTitle(rs.getString("title"));
        item.setDescription(rs.getString("description"));
        item.setType(rs.getString("type"));
        item.setContact(rs.getString("contact"));
        item.setCreateTime(rs.getTimestamp("create_time"));
        item.setUsername(rs.getString("username"));
        return item;
    }

    public List<Item> getAllItems() {
        return searchItems("");
    }

    public List<Item> searchItems(String keyword) {
        List<Item> list = new ArrayList<>();
        String sql = "SELECT i.*, u.username FROM items i JOIN users u ON i.user_id = u.id " +
                     "WHERE i.title LIKE ? OR i.description LIKE ? ORDER BY i.create_time DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, "%" + keyword + "%");
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