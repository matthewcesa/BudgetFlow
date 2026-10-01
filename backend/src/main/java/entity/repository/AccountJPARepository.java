package entity.repository;

import entity.Account;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AccountJPARepository extends JpaRepository<Account, UUID> {
    public List<Account> findByUserAndIsActive(UUID userId);
}
