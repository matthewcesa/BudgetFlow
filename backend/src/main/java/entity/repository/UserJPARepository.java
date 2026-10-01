package entity.repository;

import entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface UserJPARepository extends JpaRepository<User, UUID> {
        public User findByEmail(String email);
        public boolean existsByEmail(String email);
}
