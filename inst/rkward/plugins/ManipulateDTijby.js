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

    var data = getValue('dt_data');
    var i_filt = cleanStr(getValue('i_filter'));
    var j_mode = getValue('j_mode');
    var by_raw = getValue('by_vars');

    // Ensure we are working with a data.table object
    echo('target_data <- data.table::as.data.table(' + data + ')\n');

    // Process 'i' (Filter rows)
    var i_expr = '';
    if (i_filt !== '') {
        i_expr = i_filt;
    }

    // Process 'j' (Columns operations)
    var j_expr = '';
    if (j_mode === 'select') {
        var sel_vars = getValue('j_sel_vars').split('\n').map(parseVar).filter(Boolean);
        if (sel_vars.length > 0) {
            j_expr = '.(' + sel_vars.map(function(v){ return '`' + v + '`'; }).join(', ') + ')';
        }
    } else if (j_mode === 'aggregate') {
        var agg_var = parseVar(getValue('j_agg_var'));
        var stat = getValue('j_agg_stat');
        if (agg_var !== '') {
            var val_str = '`' + agg_var + '`';
            if (stat === 'count') j_expr = '.(Count = .N)';
            else if (stat === 'mean') j_expr = '.(Mean = mean(' + val_str + ', na.rm=TRUE))';
            else if (stat === 'sum') j_expr = '.(Sum = sum(' + val_str + ', na.rm=TRUE))';
            else if (stat === 'median') j_expr = '.(Median = median(' + val_str + ', na.rm=TRUE))';
            else if (stat === 'max') j_expr = '.(Max = max(' + val_str + ', na.rm=TRUE))';
            else if (stat === 'min') j_expr = '.(Min = min(' + val_str + ', na.rm=TRUE))';
        } else if (stat === 'count') {
            j_expr = '.N'; // Simple row count
        }
    } else if (j_mode === 'update') {
        var up_col = cleanStr(getValue('j_upd_col'));
        var up_expr = cleanStr(getValue('j_upd_expr'));
        if (up_col !== '' && up_expr !== '') {
            j_expr = '`:=`(`' + up_col + '` = ' + up_expr + ')';
        }
    }

    // Process 'by' (Grouping mechanism)
    var by_expr = '';
    if (by_raw !== '') {
        var by_arr = by_raw.split('\n').map(parseVar).filter(Boolean);
        if (by_arr.length > 0) {
            by_expr = 'by = .(' + by_arr.map(function(v){ return '`' + v + '`'; }).join(', ') + ')';
        }
    }

    // Assembly of the DT[i, j, by] syntax
    var dt_args = [];
    dt_args.push(i_expr !== '' ? i_expr : '');

    if (j_expr !== '' || by_expr !== '') {
        dt_args.push(j_expr !== '' ? j_expr : '');
    }
    if (by_expr !== '') {
        dt_args.push(by_expr);
    }

    var query = 'target_data[' + dt_args.join(', ') + ']';
    echo('res_dt <- ' + query + '\n');

    // Handle Sorting via chained 'order' (DT[...][order(...)])
    var ord_raw = getValue('i_order');
    if (ord_raw !== '') {
        var ord_arr = ord_raw.split('\n').map(parseVar).filter(Boolean);
        if (ord_arr.length > 0) {
            var pfx = getValue('i_desc') === 'TRUE' ? '-' : '';
            var order_str = 'order(' + ord_arr.map(function(v){ return pfx + '`' + v + '`'; }).join(', ') + ')';
            echo('res_dt <- res_dt[' + order_str + ']\n');
        }
    }

    echo('preview_data <- as.data.frame(head(res_dt, 50))\n');
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Manipulate (DT[i,j,by]) results")).print();	
	}
    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header("data.table: Manipulation Summary")\n');
        echo('rk.print(paste("<b>Rows:</b>", nrow(res_dt), "| <b>Columns:</b>", ncol(res_dt)))\n');

        if (getValue('save_res.active')) {
            echo('rk.print(paste0("<b>Object saved to workspace as: </b><code>", "' + getValue('save_res') + '", "</code>"))\n');
        }

        echo('rk.print("<hr>")\n');
    }
  
	if(!is_preview) {
		//// save result object
		// read in saveobject variables
		var saveRes = getValue("save_res");
		var saveResActive = getValue("save_res.active");
		var saveResParent = getValue("save_res.parent");
		// assign object to chosen environment
		if(saveResActive) {
			echo(".GlobalEnv$" + saveRes + " <- res_dt\n");
		}	
	}

}

