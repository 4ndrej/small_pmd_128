<?php



$U = 5;
$UD = 0.7; // DIODE FORWARD VOLTAGE

$R1 = 1200; // DATA
$R2 = 1000;  // BRIGHT

$R3 = 560;  // SYNC
$R4 = 100;  // 

$R14 = $R1*$R4/($R1+$R4);
$U_Black = $U * ( $R14 / ($R3 + $R14 ) ); 

$R13 = $R1*$R3/($R1+$R3);

$U_White = $U * ( $R4 / ($R4 + $R13 ) ); 

$I2 =  ($U-$UD)/($R2+$R4);
$I1 = $U/($R13 + $R4);
$U_White2 = $R4 * ( $I1 + $I2 );

echo $U_Black . " ";
echo $U_White . " ";
echo $U_White2 . " ";


?>  
