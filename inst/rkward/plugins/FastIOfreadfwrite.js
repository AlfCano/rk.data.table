// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!

// define variables globally
    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, "\\'").replace(/"/g, '\\"');
    }

    function parseVar(fullPath) {
        if (!fullPath) return '';
        var raw_col = '';
        if (fullPath.indexOf('[[') > -1) {
            var parts = fullPath.split('[[');
            var inner = parts[1].replace(']]', '');
            raw_col = inner.replace(/["']/g, '');
        } else if (fullPath.indexOf('$') > -1) {
            raw_col = fullPath.split('$')[1];
        } else {
            raw_col = fullPath;
        }
        return raw_col;
    }
  

function preview(){
	preprocess(true);
	calculate(true);
	printout(true);
}

function preprocess(is_preview){
	// add requirements etc. here
	if(is_preview) {
		echo("if(!base::require(data.table)){stop(" + i18n("Preview not available, because package data.table is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(data.table)\n");
	}
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var mode = getValue('io_mode');

    if (mode === 'read') {
        var f_in = cleanStr(getValue('fread_file')).replace(/\\/g, '/'); // Fix Windows paths
        var sep = getValue('fread_sep');

        if (f_in !== '') {
            var sep_val = (sep === 'TAB') ? '\\t' : sep;
            var args = ['"' + f_in + '"'];
            if (sep !== 'auto') args.push('sep = "' + sep_val + '"');

            // EL TRUCO DEL PREVIEW PARA ARCHIVOS MASIVOS:
            if (typeof is_preview !== 'undefined' && is_preview) {
                // Solo lee 50 líneas y convierte a data.frame para el visor
                args.push('nrows = 50');
                echo('preview_data <- as.data.frame(data.table::fread(' + args.join(', ') + '))\n');
            } else {
                // Ejecución real final (Se asigna al 'initial' de saveobj)
                echo('imported_dt <- data.table::fread(' + args.join(', ') + ')\n');
            }
        }
    } else {
        var dt_out = getValue('fwrite_obj');
        var f_out = cleanStr(getValue('fwrite_file')).replace(/\\/g, '/');
        var sep_out = getValue('fwrite_sep');

        if (dt_out !== '' && f_out !== '') {
            var sep_w_val = (sep_out === 'TAB') ? '\\t' : sep_out;
            echo('data.table::fwrite(x = ' + dt_out + ', file = "' + f_out + '", sep = "' + sep_w_val + '")\n');

            // En modo escritura, le pasamos las primeras 50 filas del objeto existente al preview
            if (typeof is_preview !== 'undefined' && is_preview) {
                echo('preview_data <- as.data.frame(head(' + dt_out + ', 50))\n');
            }
        }
    }
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Fast I/O (fread & fwrite) results")).print();	
	}
    var mode = getValue('io_mode');

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header("data.table: Fast I/O")\n');

        if (mode === 'read') {
            var f_in = cleanStr(getValue('fread_file')).replace(/\\/g, '/');
            if (f_in !== '') {
                // save_obj maneja la asigación final, solo imprimimos el resumen
                echo('rk.print(paste0("<b>Imported file: </b>", "' + f_in + '", "<br><b>Saved to workspace as: </b><code>", "' + getValue('fread_save') + '", "</code>"))\n');
            }
        } else {
            var dt_out = getValue('fwrite_obj');
            var f_out = cleanStr(getValue('fwrite_file')).replace(/\\/g, '/');
            if (dt_out !== '' && f_out !== '') {
                echo('rk.print(paste0("<b>Exported object: </b><code>", "' + dt_out + '", "</code><br><b>Saved to disk as: </b>", "' + f_out + '"))\n');
            }
        }
        echo('rk.print("<hr>")\n');
    }
  
	if(!is_preview) {
		//// save result object
		// read in saveobject variables
		var freadSave = getValue("fread_save");
		var freadSaveActive = getValue("fread_save.active");
		var freadSaveParent = getValue("fread_save.parent");
		// assign object to chosen environment
		if(freadSaveActive) {
			echo(".GlobalEnv$" + freadSave + " <- imported_dt\n");
		}	
	}

}

