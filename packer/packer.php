<?

    function prepare_pmd_file( $file_name, $file_no ) 
    {
        // return string - File content with recomputed file number
	
        $f = fopen($file_name, "rb");	
        $len = filesize ( $file_name );
        $content = fread($f, $len);
    
        $content_a = array();
        for( $i = 0 ;$i < 64; $i++ )
        {
            $content_a[$i] = ord( substr($content,$i,1));
        } 
    
    
        $count55 = 0;
        $i = 0;
        while( $count55 < 16 && $i < 200)
        {
            if( $content_a[$i++] == 0x55 ) $count55++;  
      
        }
        
	if( $i < 200 ) // classic PMD Tape file format detected
	{

	   $tmp = $content_a[$i] ;
           $sum = $content_a[$i + 14] ;
           $sum -= $tmp;
           $sum += $file_no;
           $sum = $sum & 0xff; 
    
           $content[$i] = chr($file_no);
           $content[$i+14] = chr($sum);
	}

        fclose($f);
    
        return $content;
   }	








  $d = "..\\rom1\\";
  $dir = opendir( $d );
  $files = array();
  set_time_limit(100);
  
  while( $row = readdir( $dir ) )
  {
    $row = strtolower($row);
    if( in_array( $row, array(".","..", "index.php","index.php.bak", "flash.rom","const_generated.asm"))) continue;
    $files[] = $row;
  
  }  

  //$files = array( $files[0]); // only one file --> TEST

  //print_r($files);  
  
  $output = fopen("games.pack", "wb");
  $from = 0; // hexa counter 
  
  
  sort( $files );
  $file_no = 0;
  $database = '';  


  foreach( $files AS $file )
  {
  
    $content = prepare_pmd_file( $d . $file, $file_no++ );

    $packed = PACK_XXX($content);
    $len_packed = strlen($packed);

    $from += $len_packed;
    

    
    fwrite($output, $packed, $len_packed );
    
    $len_content_total += strlen($content);
    $len_packed_total += strlen($packed);
    echo " ".(strlen($content));
    echo " ".(strlen($packed));
    echo " ".round(100*(-strlen($packed)+strlen($content))/strlen($content))." % \n\r";


  }
  
     
  
  fclose($output);
  
  echo "usetril som " . ($len_content_total-$len_packed_total). " bajtov \n\r";
  echo "Zostava " . (128*1024 - 9216 - $len_packed_total). " bajtov \n\r";
  return;


  

  function PACK_XXX($content)
  {
       $n = 1;
       $aaa = array();
       $t_size = pow(256,$n);
       for($i = 0; $i < $t_size; $i ++ ) $aaa[$i]=0;
       $c_size = strlen( $content);
       
       for( $i =0; $i < $c_size; $i++ )
       {
          $window = substr($content,$n);


       }
       

       

       
       arsort($aaa);
       print_r($aaa);

     return $str;

  }
  

  

  $bbb= array();	
  for($i = 0; $i < 1; $i ++ ) $bbb[$i]=0;
  $p = count($rom);

  for($i=0;$i<$p; $i++)
  {
    $c = $rom[$i];
    $j = $i+1;
    while( $rom[$j] == $c ) $j++;
    $bbb[$j-$i]++;
    $i=$j;
  }

  asort($bbb);
  print_r($bbb);
  

  
  function PACK_RLE2($str)
  {
     $rv ='';	

     for($i = 0; $i < strlen($str ) ; $i++ )
     {
       $c = substr($str,$i,1);     	
       for($j = 1;  $c == substr($str,$i+$j,1) && $j <= 1+4 ; $j++ );     	// kolko znakov sa opakuje
       if( $j > 1 ) 
       {
       	  $rv .=  $c; "1BBBBBBBBCC";  // cc = 2,3,4,5
       	  $i+= $j-1; 
       }
       else
       {
         $rv .= "0BBBBBBBB";
       }
     }	 
  	
     return $rv; 	
  }
  

?>

