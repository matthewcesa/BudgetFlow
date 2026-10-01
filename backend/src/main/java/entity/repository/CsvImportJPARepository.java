package entity.repository;

import entity.CsvImport;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface CsvImportJPARepository extends JpaRepository<CsvImport, UUID> {
    public CsvImport findByFilename(String filename);
}
