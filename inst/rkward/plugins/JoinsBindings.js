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

    var mode = getValue('cmb_mode');

    if (mode === 'join') {
        var x = getValue('cmb_x');
        var y = getValue('cmb_y');
        var type = getValue('cmb_join_type');
        var on_keys = cleanStr(getValue('cmb_on'));

        echo('dt_x <- data.table::as.data.table(' + x + ')\n');
        echo('dt_y <- data.table::as.data.table(' + y + ')\n');

        var by_args = '';
        if (on_keys !== '') {
            // Support both direct string inputs ('id') and manual vectors ('c("id1", "id2")')
            if (on_keys.indexOf('c(') > -1) {
                by_args = ', by = ' + on_keys;
            } else {
                var keys_arr = on_keys.split(',').map(function(s){return '"' + s.trim() + '"';});
                by_args = ', by = c(' + keys_arr.join(', ') + ')';
            }
        }

        if (type === 'anti') {
            // Anti-join requires 'on' instead of 'by' in data.table: X[!Y]
            var on_anti = by_args.replace('by =', 'on =');
            echo('res_dt <- dt_x[!dt_y' + on_anti + ']\n');
        } else {
            var all_args = '';
            if (type === 'left') all_args = ', all.x = TRUE';
            else if (type === 'right') all_args = ', all.y = TRUE';
            else if (type === 'full') all_args = ', all = TRUE';
            else if (type === 'inner') all_args = ', all = FALSE';

            // We use merge() for robustness on standard joins
            echo('res_dt <- merge(dt_x, dt_y' + all_args + by_args + ')\n');
        }

    } else {
        var dts = getValue('cmb_bind_list');
        var fill = getValue('cmb_bind_fill') === 'TRUE' ? 'TRUE' : 'FALSE';
        var idcol = cleanStr(getValue('cmb_bind_idcol'));

        // Handle multiple datasets selected in the varslot
        var dt_arr = dts.split('\n').filter(Boolean);
        var list_str = 'list(' + dt_arr.join(', ') + ')';
        var id_str = (idcol !== '') ? ', idcol = "' + idcol + '"' : '';

        echo('res_dt <- data.table::rbindlist(' + list_str + ', use.names = TRUE, fill = ' + fill + id_str + ')\n');
    }

    // Native Data Preview
    echo('preview_data <- as.data.frame(head(res_dt, 50))\n');
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Joins & Bindings results")).print();	
	}
    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header("data.table: Combine Data Summary")\n');

        var mode = getValue('cmb_mode');
        var op = (mode === 'join') ? 'Merge / Join (' + getValue('cmb_join_type') + ')' : 'Bind Rows (rbindlist)';

        echo('rk.print(paste("<b>Operation:</b>", "' + op + '", "| <b>Dimensions:</b>", nrow(res_dt), "rows x", ncol(res_dt), "cols"))\n');

        if (getValue('cmb_save.active')) {
            echo('rk.print(paste0("<b>Object saved as: </b><code>", "' + getValue('cmb_save') + '", "</code>"))\n');
        }
        echo('rk.print("<hr>")\n');
    }
  
	if(!is_preview) {
		//// save result object
		// read in saveobject variables
		var cmbSave = getValue("cmb_save");
		var cmbSaveActive = getValue("cmb_save.active");
		var cmbSaveParent = getValue("cmb_save.parent");
		// assign object to chosen environment
		if(cmbSaveActive) {
			echo(".GlobalEnv$" + cmbSave + " <- res_dt\n");
		}	
	}

}

