package entity;

import entity.enums.CategoryType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.UUID;

@Entity
@Table(name = "category")
@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "category_id")
    private UUID category_id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(nullable = false, length = 255)
    private String name;

    @Column(length = 100)
    private String icon;

    @Column(length = 8) //Hex code
    private String color;

    @JdbcTypeCode(SqlTypes.NAMED_ENUM) // pour pas envoyer un varchar a postgres
    @Column(name = "type", nullable = false, columnDefinition = "category_type")
    private CategoryType type;

    @Column(name = "is_default", nullable = false)
    private boolean isDefault = false;
}
