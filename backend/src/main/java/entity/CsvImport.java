package entity;

import entity.enums.ImportStatus;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "csv_import")
@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class CsvImport {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "csv_import_id")
    private UUID csv_import_id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "account_id", nullable = false)
    private Account account;

    @Column(nullable = false, unique = true, length = 255)
    private String filename;

    @JdbcTypeCode(SqlTypes.NAMED_ENUM) // pour pas envoyer un varchar a postgres
    @Column(name = "status", nullable = false, columnDefinition = "import_status")
    private ImportStatus import_status = ImportStatus.PENDING;

    @Column(name = "rows_total", nullable = false)
    private BigDecimal rowsTotal = BigDecimal.ZERO;

    @Column(name = "rows_imported", nullable = false)
    private BigDecimal rowsImported = BigDecimal.ZERO;

    @Column(name = "rows_skipped", nullable = false)
    private BigDecimal rowsSkipped = BigDecimal.ZERO;

    @CreationTimestamp
    @Column(name = "imported_at", nullable = false)
    private Instant ImportedAt;
}
