package entity.repository;

import entity.Category;
import entity.enums.CategoryType; // Import de ton enum
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CategoryJPARepository extends JpaRepository<Category, UUID> {

    List<Category> findByUserUserId(UUID userId);

    List<Category> findByIsDefaultTrue();

    List<Category> findByType(CategoryType type);
}