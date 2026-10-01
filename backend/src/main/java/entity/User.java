package entity;

import entity.enums.PlanType;
import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID user_id;

    @Email
    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String name;

    @Column(name = "avatar_url", length = 500)
    private String text;

    @Column(nullable = false, length = 3)
    private String currency = "EUR";

    @Column(nullable = false, length = 10)
    private String locale = "fr-FR";

    @JdbcTypeCode(SqlTypes.NAMED_ENUM) // pour pas envoyer un varchar a postgres
    @Column(name = "plan", nullable = false, columnDefinition = "plan_type")
    private PlanType plan = PlanType.FREE;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
