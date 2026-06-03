package ec.edu.espe.gestion_publicaciones.firmaec.repository;

import ec.edu.espe.gestion_publicaciones.firmaec.model.entity.FirmaElectronicaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FirmaElectronicaRepository extends JpaRepository<FirmaElectronicaEntity, Long> {

    List<FirmaElectronicaEntity> findByDocumentoFirmableId(Long documentoFirmableId);

    Optional<FirmaElectronicaEntity> findByDocumentoFirmableIdAndCedulaFirmanteAndEstado(
            Long documentoFirmableId, String cedulaFirmante, String estado);

    List<FirmaElectronicaEntity> findByCedulaFirmanteAndEstado(String cedulaFirmante, String estado);
}
