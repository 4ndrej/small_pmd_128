<?php



function rom_modul($output, $rom, $comment = "" )
{
  echo 'A';
  $per_line = 40; // this must be divided by two (organization FLASH is 64K x 16bits words)
  $length = strlen($rom);

  fwrite($output, "\n; FILE: \"$comment\", size=".$length. "\n\n");

  $tmp = array();
//         $tmp[$i] = sprintf("0x%02X", ord($rom[$i]));
  for( $i = 0; $i < $length; $i++ )
  {
         $tmp[$i] = ord($rom[$i]);
  } 
  if($length%2 == 1)
  {
     	$tmp[] = '0xee'; //padding 
  }   
  
  for( $i = 0; $i < $length; $i += $per_line)
  {
     fwrite($output,"\t.db "  . join(',',array_slice($tmp,$i,$per_line)) . sprintf("\t;\t%04X\n", $i));  
  }
  echo 'B';

 
}



/*
function last_char( $c ) // zabezpeci pakovanie rovnakych sekvencii > 254 znakov
                           // 00 00 FE 00 00 A0 --> 00 00 FE 00 A0 
{
   static $last = null;
   
   $rv = ( $last == $c );
   
   $last = $c;
   
   return $rv;
  	
}	
*/
  
  function PACK_RLE($str )
  {
//     return $str; //disabled

     $rv ='';	
     $last = '';

     for( $i = 0; $i < strlen($str); $i++ )
     {
       $c = $str[$i];     	
       for($j = 1;  $c == $str[$i+$j] && $j < 254; $j++ );     	// kolko znakov sa opakuje
       $rv .= $c;
       if( $j 	> 1 ) 
       {
       	  $cond = ($last == $c);
	  $last = $c;
       	  $rv .= ($cond ? '' : $c ) . chr($j+$cond);
       	  $i+= $j-1; 
       }
       $last = $c;
     }	 
  	
     return $rv; 	
  }







  
  $games_dir = $_SERVER['argv'][1];
  $oname = $_SERVER['argv'][2] ? $_SERVER['argv'][2] : "${games_dir}.asm";
  if( ! preg_match("/rom\\d+/",$games_dir))
  {
     $rom = file_get_contents("$games_dir.rom");
     $output = fopen($oname, "wt");
     rom_modul($output, $rom, $games_dir);
     fclose($output);
	
     return;
  }
  
  $d = "..\\${games_dir}\\";
  $dir = opendir( $d );
  $files = array();
  set_time_limit(180);
  
  while( $row = readdir( $dir ) )
  {
    $row = strtolower($row);
    if( in_array( $row, array(".","..", "index.php","index.php.bak", "flash.rom","const_generated.asm"))) continue;
//    print_r($row);
    $files[] = $row;
  //  print_r($files);  
  
    //echo "<br>";
  }  
  
  print_r($files);  
  
  /*
  $tmp = $files[0];
  $files[0] = $files[1];
  $files[1] = $tmp;
  */

  $output = fopen($oname, "wb");
  $from = 0; // hexa counter 
  
  
  sort( $files );
  $file_no = 0;
  $database = '';  
  foreach( $files AS $file )
  {
    $f = fopen($d . $file, "rb");	
    $len = filesize ( $d . $file );
    $content = fread($f, $len);
    preg_match("/^([^\.]*)\..*/",$file,$matched);
    $name2 = strtr($matched[1]," ","_" );
    $name = UCFirst($matched[1]);
    
    echo sprintf("%06X", $from ) . " - " . sprintf("%06X ", $from + $len - 1 ); 
     
    echo "$file ";
    
    $content_a = array();
    for( $i = 0 ;$i < 64; $i++ )
    {
     $content_a[$i] = ord( substr($content,$i,1));
    } 
    
    
    $count55 = 0;
    $i = 0;
    while( $count55 < 16 )
    {
      if( $content_a[$i++] == 0x55 ) $count55++;  
      
    }
    
     
    $tmp = $content_a[$i] ;
    echo " number $tmp => $file_no ";
    $sum = $content_a[$i + 14] ;
    echo " sum: $sum => ";
    $sum -= $tmp;
    $sum += $file_no;
    $sum = $sum & 0xff; 
    echo "$sum ";
    
    
    
    
    $content[$i] = chr($file_no);
    $content[$i+14] = chr($sum);
    
    $packed = PACK_RLE($content);
    $len_packed = strlen($packed);

    $from += $len_packed;
    

    rom_modul($output, $packed, $file);
    fclose($f);
    
    $len_content_total += strlen($content);
    $len_packed_total += strlen($packed);
    echo " ".(strlen($content));
    echo " ".(strlen($packed));
    echo " ".round(100*(-strlen($packed)+strlen($content))/strlen($content))." % \n\r";

    $file_no++;
//    $file_no = 0;

  }
  
     
  
  fclose($output);
  
  echo "usetril som " . ($len_content_total-$len_packed_total). " bajtov \n\r";
  echo "Zostava " . (128*1024 - 9216 - $len_packed_total). " bajtov \n\r";

?>

