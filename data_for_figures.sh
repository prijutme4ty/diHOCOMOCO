mkdir -p figures

# Number of peak sets and data sets by TF
find control/control/ -xtype f \
  | ruby -e 'result = readlines.map{|fn| File.basename(fn.chomp, ".control.mfa") }.group_by{|peakset| peakset.split(".")[0] }.map{|tf,peaksets| datasets = peaksets.map{|peakset| peakset.split(".")[1] }.uniq; [tf, peaksets.size, datasets.size] }; result.each{|infos| puts infos.join("\t") }' \
  > figures/num_peaksets_and_datasets_by_tf.tsv

# True positive rate measured on control datasets for precalculated thresholds (0.001; 0.0005; 0.0001)
./calculate_tpr_by_motif.sh 0.65 > figures/motif_tprs_by_pval_0.65.tsv

# logROC-curves for all human motifs of specified TF (measured on all peaks of all TF datasets)
for TF in EGR1_HUMAN; do # CTCF_HUMAN ANDR_HUMAN ESR1_HUMAN MYC_HUMAN FOXA1_HUMAN; do
  mkdir -p figures/logauc_curves/$TF
  for MODEL in `find models/pwm/di/all/$TF -xtype f | xargs -n1 basename -s .dpwm`; do
    MODEL_LENGTH=$(cat models/pwm/di/all/$TF/${MODEL}.dpwm | wc -l)
    ( \
      echo $MODEL; \
      find control/control/ -name "$TF.*.mfa" \
        | xargs -r -n1 -I {CNTRL} echo "cat {CNTRL} \
        | ruby renameMultifastaSequences.rb all"  | bash \
        | java -cp sarus.jar ru.autosome.di.SARUS - models/pwm/di/all/$TF/${MODEL}.dpwm besthit  \
        | ruby calculate_auc.rb $MODEL_LENGTH models/thresholds/di/HUMAN_background/$TF/${MODEL}.thr di --print-logroc \
    ) > "figures/logauc_curves/$TF/$MODEL"
  done
done

