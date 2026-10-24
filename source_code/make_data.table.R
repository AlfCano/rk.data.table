local({
  # =========================================================================================
  # 1. Setup and Metadata
  # =========================================================================================
  require(rkwarddev)

  plugin_name <- "rk.data.table"

  about_info <- rk.XML.about(
    name = plugin_name,
    author = person(
      given = "Alfonso",
      family = "Cano",
      email = "alfonso.cano@correo.buap.mx",
      role = c("aut", "cre")
    ),
    about = list(
      desc = "A Lightning-Fast GUI for data.table: Data manipulation, reshaping, and massive file I/O",
      version = "0.0.1",
      url = "https://github.com/AlfCano/rk.data.table",
      license = "GPL (>= 3)"
    )
  )

  dependencies_node <- rk.XML.dependencies(
    dependencies = list(R.min = "4.0.0"),
    package = list(c(name = "data.table"))
  )

  h_dt <- list("data", "data.table")

  # Global JavaScript Helper Functions
  js_helpers <- "
    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, \"\\\\'\").replace(/\"/g, '\\\\\"');
    }

    function parseVar(fullPath) {
        if (!fullPath) return '';
        var raw_col = '';
        if (fullPath.indexOf('[[') > -1) {
            var parts = fullPath.split('[[');
            var inner = parts[1].replace(']]', '');
            raw_col = inner.replace(/[\"']/g, '');
        } else if (fullPath.indexOf('$') > -1) {
            raw_col = fullPath.split('$')[1];
        } else {
            raw_col = fullPath;
        }
        return raw_col;
    }
  "

  # =========================================================================================
  # 2. MAIN UI: DT[i, j, by] (Data Manipulation)
  # =========================================================================================

  # --- UI Elements ---

  # Selector and Data Source (Will be placed globally on the left)
  dt_vs <- rk.XML.varselector(id.name = "dt_vs")
  dt_data <- rk.XML.varslot("Data.frame / data.table", source = "dt_vs", classes = "data.frame", required = TRUE, id.name = "dt_data")

  # i: Filter and Order
  i_filter <- rk.XML.input("Filter rows (Expression for 'i', e.g., age > 18 & sex == 'F')", id.name = "i_filter")
  i_order <- rk.XML.varslot("Sort by variable(s) (order)", source = "dt_vs", multi = TRUE, id.name = "i_order")
  i_desc <- rk.XML.cbox("Sort descending (-)", value = "TRUE", chk = FALSE, id.name = "i_desc")

  # j: Action selector
  j_mode <- rk.XML.radio("Action for Columns ('j')", options = list(
    "Keep / Drop Columns" = list(val = "select", chk = TRUE),
    "Aggregate / Summarize" = list(val = "aggregate"),
    "Update by Reference (:=)" = list(val = "update")
  ), id.name = "j_mode")

  # j: Frames based on Action
  j_select_vars <- rk.XML.varslot("Columns to keep", source = "dt_vs", multi = TRUE, id.name = "j_sel_vars")
  frm_select <- rk.XML.frame(j_select_vars, label = "Subset Columns", id.name = "frm_select")

  j_agg_var <- rk.XML.varslot("Variable to Summarize (Leave blank for row count)", source = "dt_vs", id.name = "j_agg_var")
  j_agg_stat <- rk.XML.dropdown("Statistic", options = list(
    "Count (.N)" = list(val = "count", chk = TRUE),
    "Mean" = list(val = "mean"),
    "Sum" = list(val = "sum"),
    "Median" = list(val = "median"),
    "Max" = list(val = "max"),
    "Min" = list(val = "min")
  ), id.name = "j_agg_stat")
  frm_aggregate <- rk.XML.frame(j_agg_var, j_agg_stat, label = "Compute Summary", id.name = "frm_aggregate")

  j_upd_col <- rk.XML.input("New or Existing Column Name", id.name = "j_upd_col")
  j_upd_expr <- rk.XML.input("Expression (e.g., var1 * var2 / 100)", id.name = "j_upd_expr")
  frm_update <- rk.XML.frame(j_upd_col, j_upd_expr, rk.XML.text("Note: Modifies the data.table directly in memory (zero copy)."), label = "Add/Update Column (:=)", id.name = "frm_update")

  # by: Grouping
  by_vars <- rk.XML.varslot("Group by variable(s) ('by')", source = "dt_vs", multi = TRUE, id.name = "by_vars")



  # Output
  save_res <- rk.XML.saveobj("Save result as", initial = "res_dt", chk = TRUE, id.name = "save_res")

  # --- Logic for UI ---

  cond_select <- rk.XML.convert(sources = list(j_mode), mode = c(equals = "select"), id.name = "cond_select")
  cond_aggregate <- rk.XML.convert(sources = list(j_mode), mode = c(equals = "aggregate"), id.name = "cond_aggregate")
  cond_update <- rk.XML.convert(sources = list(j_mode), mode = c(equals = "update"), id.name = "cond_update")

  logic_dt <- rk.XML.logic(
    cond_select, cond_aggregate, cond_update,
    rk.XML.connect(governor = dt_data, get = "available", client = dt_vs, set = "root"),
    rk.XML.connect(governor = cond_select, client = frm_select, set = "visible"),
    rk.XML.connect(governor = cond_aggregate, client = frm_aggregate, set = "visible"),
    rk.XML.connect(governor = cond_update, client = frm_update, set = "visible")
  )

  # --- UPDATED Layout ---

  # 1. We build the tabbook containing ONLY the right-side elements
  tab_dt <- rk.XML.tabbook(tabs = list(
    "Data & Rows (i)" = rk.XML.col(
      dt_data,
      rk.XML.frame(i_filter, i_order, i_desc, label = "Filter and Sort ('i')"),
      rk.XML.stretch()
    ),
    "Columns (j)" = rk.XML.col(
      j_mode,
      frm_select,
      frm_aggregate,
      frm_update,
      rk.XML.stretch()
    ),
    "Groups (by) & Output" = rk.XML.col(
      rk.XML.frame(by_vars, label = "Grouping ('by')"),
      rk.XML.frame(save_res, label = "Export"),
      rk.XML.stretch()
    )
  ))

  # 2. We place the varselector on the left side, side-by-side with the tabbook
  dialog_dt <- rk.XML.dialog(
    rk.XML.row(
      dt_vs,
      rk.XML.col(tab_dt)
    ),
    label = "data.table: Manipulate (i, j, by)"
  )

  # 3. preview
   dt_preview <- rk.XML.preview(mode = "data", label = "Preview (Top 50 rows)")

  # 3.2 dialog
  dialog_dt <- rk.XML.dialog(
    rk.XML.row(
      dt_vs,
      rk.XML.col(tab_dt)
    ),
    dt_preview, # <- Aquí ponemos el botón
    label = "data.table: Manipulate (i, j, by)"
  )

  # =========================================================================================
  # 3. MAIN JAVASCRIPT: DT[i, j, by]
  # =========================================================================================

  js_calc_dt <- "
    var data = getValue('dt_data');
    var i_filt = cleanStr(getValue('i_filter'));
    var j_mode = getValue('j_mode');
    var by_raw = getValue('by_vars');

    // Ensure we are working with a data.table object
    echo('target_data <- data.table::as.data.table(' + data + ')\\n');

    // Process 'i' (Filter rows)
    var i_expr = '';
    if (i_filt !== '') {
        i_expr = i_filt;
    }

    // Process 'j' (Columns operations)
    var j_expr = '';
    if (j_mode === 'select') {
        var sel_vars = getValue('j_sel_vars').split('\\n').map(parseVar).filter(Boolean);
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
        var by_arr = by_raw.split('\\n').map(parseVar).filter(Boolean);
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
    echo('res_dt <- ' + query + '\\n');

    // Handle Sorting via chained 'order' (DT[...][order(...)])
    var ord_raw = getValue('i_order');
    if (ord_raw !== '') {
        var ord_arr = ord_raw.split('\\n').map(parseVar).filter(Boolean);
        if (ord_arr.length > 0) {
            var pfx = getValue('i_desc') === 'TRUE' ? '-' : '';
            var order_str = 'order(' + ord_arr.map(function(v){ return pfx + '`' + v + '`'; }).join(', ') + ')';
            echo('res_dt <- res_dt[' + order_str + ']\\n');
        }
    }

    echo('preview_data <- as.data.frame(head(res_dt, 50))\\n');
  "

  js_print_dt <- "
    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header(\"data.table: Manipulation Summary\")\\n');
        echo('rk.print(paste(\"<b>Rows:</b>\", nrow(res_dt), \"| <b>Columns:</b>\", ncol(res_dt)))\\n');

        if (getValue('save_res.active')) {
            echo('rk.print(paste0(\"<b>Object saved to workspace as: </b><code>\", \"' + getValue('save_res') + '\", \"</code>\"))\\n');
        }

        echo('rk.print(\"<hr>\")\\n');
    }
  "
  # =========================================================================================
  # COMPONENT 2: Fast I/O (fread & fwrite)
  # =========================================================================================

  # --- UI Elements ---
  io_mode <- rk.XML.radio("Action", options = list(
    "Read File to Workspace (fread)" = list(val = "read", chk = TRUE),
    "Write Object to Disk (fwrite)" = list(val = "write")
  ), id.name = "io_mode")

  # Read (fread) Elements
  fread_file <- rk.XML.browser("File to read (.csv, .txt, etc.)", type = "file", required = FALSE, id.name = "fread_file")
  fread_sep <- rk.XML.dropdown("Separator", options = list(
    "Auto-detect" = list(val = "auto", chk = TRUE),
    "Comma (,)" = list(val = ","),
    "Tab" = list(val = "TAB"),
    "Semicolon (;)" = list(val = ";")
  ), id.name = "fread_sep")

  # AHORA SÍ: Usamos saveobj cumpliendo la Regla de Oro 3
  fread_save <- rk.XML.saveobj("Save imported data as:", initial = "imported_dt", chk = FALSE, id.name = "fread_save")

  frm_read <- rk.XML.frame(fread_file, fread_sep, fread_save, label = "Import Options (fread)", id.name = "frm_read")

  # Write (fwrite) Elements
  fwrite_vs <- rk.XML.varselector(id.name = "fwrite_vs")
  fwrite_obj <- rk.XML.varslot("Data to export", source = "fwrite_vs", classes = "data.frame", required = FALSE, id.name = "fwrite_obj")
  fwrite_file <- rk.XML.browser("Save file as", type = "savefile", required = FALSE, id.name = "fwrite_file")
  fwrite_sep <- rk.XML.dropdown("Separator", options = list(
    "Comma (,)" = list(val = ",", chk = TRUE),
    "Tab" = list(val = "TAB"),
    "Semicolon (;)" = list(val = ";")
  ), id.name = "fwrite_sep")

  frm_write <- rk.XML.frame(fwrite_obj, fwrite_file, fwrite_sep, label = "Export Options (fwrite)", id.name = "frm_write")

  # AHORA SÍ: El nodo oficial de Preview de datos
  io_preview <- rk.XML.preview(mode = "data")

  # Logic to toggle between Read and Write frames (Explicit Gray-out effect)
  cond_read <- rk.XML.convert(sources = list(string = io_mode), mode = c(equals = "read"), id.name = "cond_read")
  cond_write <- rk.XML.convert(sources = list(string = io_mode), mode = c(equals = "write"), id.name = "cond_write")

  logic_io <- rk.XML.logic(
    cond_read, cond_write,

    rk.XML.connect(governor = cond_read, client = frm_read, set = "enabled"),
    rk.XML.connect(governor = cond_write, client = fwrite_vs, set = "enabled"),
    rk.XML.connect(governor = cond_write, client = frm_write, set = "enabled"),

    rk.XML.connect(governor = fwrite_obj, get = "available", client = fwrite_vs, set = "root")
  )

  # Layout Construction
  dialog_io <- rk.XML.dialog(
    rk.XML.col(
      io_mode,
      frm_read,
      rk.XML.row(fwrite_vs, frm_write),
      io_preview, # <- Preview insertado aquí
      rk.XML.stretch()
    ),
    label = "data.table: Fast I/O (fread & fwrite)"
  )

  # --- JAVASCRIPT para I/O ---
  js_calc_io <- "
    var mode = getValue('io_mode');

    if (mode === 'read') {
        var f_in = cleanStr(getValue('fread_file')).replace(/\\\\/g, '/'); // Fix Windows paths
        var sep = getValue('fread_sep');

        if (f_in !== '') {
            var sep_val = (sep === 'TAB') ? '\\\\t' : sep;
            var args = ['\"' + f_in + '\"'];
            if (sep !== 'auto') args.push('sep = \"' + sep_val + '\"');

            // EL TRUCO DEL PREVIEW PARA ARCHIVOS MASIVOS:
            if (typeof is_preview !== 'undefined' && is_preview) {
                // Solo lee 50 líneas y convierte a data.frame para el visor
                args.push('nrows = 50');
                echo('preview_data <- as.data.frame(data.table::fread(' + args.join(', ') + '))\\n');
            } else {
                // Ejecución real final (Se asigna al 'initial' de saveobj)
                echo('imported_dt <- data.table::fread(' + args.join(', ') + ')\\n');
            }
        }
    } else {
        var dt_out = getValue('fwrite_obj');
        var f_out = cleanStr(getValue('fwrite_file')).replace(/\\\\/g, '/');
        var sep_out = getValue('fwrite_sep');

        if (dt_out !== '' && f_out !== '') {
            var sep_w_val = (sep_out === 'TAB') ? '\\\\t' : sep_out;
            echo('data.table::fwrite(x = ' + dt_out + ', file = \"' + f_out + '\", sep = \"' + sep_w_val + '\")\\n');

            // En modo escritura, le pasamos las primeras 50 filas del objeto existente al preview
            if (typeof is_preview !== 'undefined' && is_preview) {
                echo('preview_data <- as.data.frame(head(' + dt_out + ', 50))\\n');
            }
        }
    }
  "

  js_print_io <- "
    var mode = getValue('io_mode');

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header(\"data.table: Fast I/O\")\\n');

        if (mode === 'read') {
            var f_in = cleanStr(getValue('fread_file')).replace(/\\\\/g, '/');
            if (f_in !== '') {
                // save_obj maneja la asigación final, solo imprimimos el resumen
                echo('rk.print(paste0(\"<b>Imported file: </b>\", \"' + f_in + '\", \"<br><b>Saved to workspace as: </b><code>\", \"' + getValue('fread_save') + '\", \"</code>\"))\\n');
            }
        } else {
            var dt_out = getValue('fwrite_obj');
            var f_out = cleanStr(getValue('fwrite_file')).replace(/\\\\/g, '/');
            if (dt_out !== '' && f_out !== '') {
                echo('rk.print(paste0(\"<b>Exported object: </b><code>\", \"' + dt_out + '\", \"</code><br><b>Saved to disk as: </b>\", \"' + f_out + '\"))\\n');
            }
        }
        echo('rk.print(\"<hr>\")\\n');
    }
  "

  # Ensamblar el Sub-Componente
  comp_io <- rk.plugin.component(
      "Fast I/O (fread & fwrite)",
      xml = list(dialog = dialog_io, logic = logic_io),
      js = list(require = c("data.table"), globals = js_helpers, calculate = js_calc_io, printout = js_print_io),
      hierarchy = h_dt
  )

  # =========================================================================================
  # COMPONENT 3: Reshaping (melt & dcast)
  # =========================================================================================

  # --- UI Elements ---
  reshape_vs <- rk.XML.varselector(id.name = "reshape_vs")
  reshape_data <- rk.XML.varslot("Data to reshape", source = "reshape_vs", classes = "data.frame", required = TRUE, id.name = "reshape_data")

  reshape_mode <- rk.XML.radio("Reshape Action", options = list(
    "Melt: Wide to Long" = list(val = "melt", chk = TRUE),
    "Dcast: Long to Wide" = list(val = "dcast")
  ), id.name = "reshape_mode")

  # 1. Melt UI (Wide to Long)
  melt_id <- rk.XML.varslot("ID variables (Keep as rows)", source = "reshape_vs", multi = TRUE, id.name = "melt_id")
  melt_measure <- rk.XML.varslot("Measure variables (Stack into columns)", source = "reshape_vs", multi = TRUE, id.name = "melt_measure")
  melt_varname <- rk.XML.input("Name for the new 'variable' column:", initial = "variable", id.name = "melt_varname")
  melt_valname <- rk.XML.input("Name for the new 'value' column:", initial = "value", id.name = "melt_valname")

  frm_melt <- rk.XML.frame(melt_id, melt_measure, melt_varname, melt_valname, label = "Melt Options (Wide to Long)", id.name = "frm_melt")

  # 2. Dcast UI (Long to Wide)
  dcast_lhs <- rk.XML.varslot("Row variables (LHS of formula)", source = "reshape_vs", multi = TRUE, id.name = "dcast_lhs")
  dcast_rhs <- rk.XML.varslot("Column variables (RHS of formula)", source = "reshape_vs", multi = TRUE, id.name = "dcast_rhs")
  dcast_val <- rk.XML.varslot("Value variable (Fill cells with)", source = "reshape_vs", required = FALSE, id.name = "dcast_val")
  dcast_fun <- rk.XML.dropdown("Aggregation function (If multiple values per cell)", options = list(
    "Default (length/count)" = list(val = "length", chk = TRUE),
    "Sum" = list(val = "sum"),
    "Mean" = list(val = "mean"),
    "Min" = list(val = "min"),
    "Max" = list(val = "max"),
    "Paste (collapse strings)" = list(val = "function(x) paste(x, collapse=',')")
  ), id.name = "dcast_fun")

  frm_dcast <- rk.XML.frame(dcast_lhs, dcast_rhs, dcast_val, dcast_fun, label = "Dcast Options (Long to Wide)", id.name = "frm_dcast")

  # 3. Output UI
  reshape_save <- rk.XML.saveobj("Save reshaped data as:", initial = "res_dt", chk = TRUE, id.name = "reshape_save")
  reshape_preview <- rk.XML.preview(mode = "data", label = "Preview (Top 50 rows)")

  # --- UI Logic ---
  cond_melt <- rk.XML.convert(sources = list(string = reshape_mode), mode = c(equals = "melt"), id.name = "cond_melt")
  cond_dcast <- rk.XML.convert(sources = list(string = reshape_mode), mode = c(equals = "dcast"), id.name = "cond_dcast")

  logic_reshape <- rk.XML.logic(
    cond_melt, cond_dcast,
    # El varslot principal alimenta el panel izquierdo
    rk.XML.connect(governor = reshape_data, get = "available", client = reshape_vs, set = "root"),

    # Efecto Gray-out explícito (encendemos/apagamos por bloque)
    rk.XML.connect(governor = cond_melt, client = frm_melt, set = "enabled"),
    rk.XML.connect(governor = cond_dcast, client = frm_dcast, set = "enabled")
  )

  # --- Dialog Layout ---
  dialog_reshape <- rk.XML.dialog(
    rk.XML.row(
      reshape_vs,
      rk.XML.col(
        reshape_data,
        reshape_mode,
        rk.XML.row(frm_melt, frm_dcast), # Puestos uno al lado del otro
        reshape_save,
        reshape_preview,
        rk.XML.stretch()
      )
    ),
    label = "data.table: Reshape (melt & dcast)"
  )

  # --- Javascript ---
  js_calc_reshape <- "
    var data = getValue('reshape_data');
    var mode = getValue('reshape_mode');

    echo('target_data <- data.table::as.data.table(' + data + ')\\n');

    if (mode === 'melt') {
        var ids = getValue('melt_id').split('\\n').map(parseVar).filter(Boolean);
        var measures = getValue('melt_measure').split('\\n').map(parseVar).filter(Boolean);
        var var_name = cleanStr(getValue('melt_varname'));
        var val_name = cleanStr(getValue('melt_valname'));

        var melt_args = ['target_data'];

        // Formatear vectores c('var1', 'var2')
        if (ids.length > 0) melt_args.push('id.vars = c(' + ids.map(function(v){return \"'\" + v + \"'\";}).join(', ') + ')');
        if (measures.length > 0) melt_args.push('measure.vars = c(' + measures.map(function(v){return \"'\" + v + \"'\";}).join(', ') + ')');

        if (var_name !== '') melt_args.push('variable.name = \"' + var_name + '\"');
        if (val_name !== '') melt_args.push('value.name = \"' + val_name + '\"');

        echo('res_dt <- data.table::melt(' + melt_args.join(', ') + ')\\n');

    } else {
        var lhs = getValue('dcast_lhs').split('\\n').map(parseVar).filter(Boolean);
        var rhs = getValue('dcast_rhs').split('\\n').map(parseVar).filter(Boolean);
        var val_var = parseVar(getValue('dcast_val'));
        var fun_agg = getValue('dcast_fun');

        // Construir la fórmula Lado Izquierdo ~ Lado Derecho. Si están vacíos, usar punto (.)
        var lhs_str = lhs.length > 0 ? lhs.map(function(v){return '`' + v + '`';}).join(' + ') : '.';
        var rhs_str = rhs.length > 0 ? rhs.map(function(v){return '`' + v + '`';}).join(' + ') : '.';
        var form_str = lhs_str + ' ~ ' + rhs_str;

        var dcast_args = ['target_data', form_str];

        if (val_var !== '') dcast_args.push('value.var = \"' + val_var + '\"');
        if (fun_agg !== '') dcast_args.push('fun.aggregate = ' + fun_agg);

        echo('res_dt <- data.table::dcast(' + dcast_args.join(', ') + ')\\n');
    }

    // El Preview Nativo (la variable mágica que descubrimos)
    echo('preview_data <- as.data.frame(head(res_dt, 50))\\n');
  "

  js_print_reshape <- "
    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header(\"data.table: Reshape Summary\")\\n');

        var mode = getValue('reshape_mode');
        var op = (mode === 'melt') ? 'Wide to Long (melt)' : 'Long to Wide (dcast)';

        echo('rk.print(paste(\"<b>Operation:</b>\", \"' + op + '\", \"| <b>New Dimensions:</b>\", nrow(res_dt), \"rows x\", ncol(res_dt), \"cols\"))\\n');

        if (getValue('reshape_save.active')) {
            echo('rk.print(paste0(\"<b>Object saved as: </b><code>\", \"' + getValue('reshape_save') + '\", \"</code>\"))\\n');
        }
        echo('rk.print(\"<hr>\")\\n');
    }
  "

  # Ensamblamos el componente
  comp_reshape <- rk.plugin.component(
      "Reshape (melt & dcast)",
      xml = list(dialog = dialog_reshape, logic = logic_reshape),
      js = list(require = c("data.table"), globals = js_helpers, calculate = js_calc_reshape, printout = js_print_reshape),
      hierarchy = h_dt
  )

  # =========================================================================================
  # COMPONENT 4: Joins & Bindings
  # =========================================================================================

  # --- UI Elements ---

  # A dedicated varselector to pick full datasets from the Global Environment
  cmb_vs <- rk.XML.varselector(id.name = "cmb_vs")

  cmb_mode <- rk.XML.radio("Action", options = list(
    "Merge / Join (Two tables)" = list(val = "join", chk = TRUE),
    "Bind Rows (rbindlist)" = list(val = "bind")
  ), id.name = "cmb_mode")

  # 1. JOIN UI (Left, Right, Inner, Full, Anti)
  cmb_x <- rk.XML.varslot("Table X (Left)", source = "cmb_vs", classes = "data.frame", required = TRUE, id.name = "cmb_x")
  cmb_y <- rk.XML.varslot("Table Y (Right)", source = "cmb_vs", classes = "data.frame", required = TRUE, id.name = "cmb_y")

  cmb_join_type <- rk.XML.dropdown("Join Type", options = list(
    "Left Join (Keep all X)" = list(val = "left", chk = TRUE),
    "Right Join (Keep all Y)" = list(val = "right"),
    "Inner Join (Intersection)" = list(val = "inner"),
    "Full Outer Join (Keep all)" = list(val = "full"),
    "Anti Join (In X, not in Y)" = list(val = "anti")
  ), id.name = "cmb_join_type")

  cmb_on <- rk.XML.input("Keys to join on (Leave empty to auto-detect. E.g. 'id', or c('id_x'='id_y'))", id.name = "cmb_on")

  frm_join <- rk.XML.frame(rk.XML.row(cmb_x, cmb_y), cmb_join_type, cmb_on, label = "Merge / Join Options", id.name = "frm_join")

  # 2. BIND UI (rbindlist)
  cmb_bind_list <- rk.XML.varslot("Data tables to bind", source = "cmb_vs", classes = "data.frame", multi = TRUE, required = TRUE, id.name = "cmb_bind_list")
  cmb_bind_fill <- rk.XML.cbox("Fill missing columns with NAs (fill = TRUE)", value = "TRUE", chk = TRUE, id.name = "cmb_bind_fill")
  cmb_bind_idcol <- rk.XML.input("Create ID column (e.g., 'source_table', leave empty for none)", id.name = "cmb_bind_idcol")

  frm_bind <- rk.XML.frame(cmb_bind_list, cmb_bind_fill, cmb_bind_idcol, label = "Bind Rows Options (rbindlist)", id.name = "frm_bind")

  # 3. Output UI
  cmb_save <- rk.XML.saveobj("Save combined data as:", initial = "res_dt", chk = TRUE, id.name = "cmb_save")
  cmb_preview <- rk.XML.preview(mode = "data", label = "Preview (Top 50 rows)")

  # --- UI Logic ---
  cond_join <- rk.XML.convert(sources = list(string = cmb_mode), mode = c(equals = "join"), id.name = "cond_join")
  cond_bind <- rk.XML.convert(sources = list(string = cmb_mode), mode = c(equals = "bind"), id.name = "cond_bind")

  logic_cmb <- rk.XML.logic(
    cond_join, cond_bind,
    # Enable/Disable frames based on Radio selection
    rk.XML.connect(governor = cond_join, client = frm_join, set = "enabled"),
    rk.XML.connect(governor = cond_bind, client = frm_bind, set = "enabled")
  )

  # --- Dialog Layout ---
  dialog_cmb <- rk.XML.dialog(
    rk.XML.row(
      cmb_vs, # Left panel for dataset selection
      rk.XML.col(
        cmb_mode,
        frm_join,
        frm_bind,
        cmb_save,
        cmb_preview,
        rk.XML.stretch()
      )
    ),
    label = "data.table: Joins & Bindings"
  )

  # --- Javascript ---
  js_calc_cmb <- "
    var mode = getValue('cmb_mode');

    if (mode === 'join') {
        var x = getValue('cmb_x');
        var y = getValue('cmb_y');
        var type = getValue('cmb_join_type');
        var on_keys = cleanStr(getValue('cmb_on'));

        echo('dt_x <- data.table::as.data.table(' + x + ')\\n');
        echo('dt_y <- data.table::as.data.table(' + y + ')\\n');

        var by_args = '';
        if (on_keys !== '') {
            // Support both direct string inputs ('id') and manual vectors ('c(\"id1\", \"id2\")')
            if (on_keys.indexOf('c(') > -1) {
                by_args = ', by = ' + on_keys;
            } else {
                var keys_arr = on_keys.split(',').map(function(s){return '\"' + s.trim() + '\"';});
                by_args = ', by = c(' + keys_arr.join(', ') + ')';
            }
        }

        if (type === 'anti') {
            // Anti-join requires 'on' instead of 'by' in data.table: X[!Y]
            var on_anti = by_args.replace('by =', 'on =');
            echo('res_dt <- dt_x[!dt_y' + on_anti + ']\\n');
        } else {
            var all_args = '';
            if (type === 'left') all_args = ', all.x = TRUE';
            else if (type === 'right') all_args = ', all.y = TRUE';
            else if (type === 'full') all_args = ', all = TRUE';
            else if (type === 'inner') all_args = ', all = FALSE';

            // We use merge() for robustness on standard joins
            echo('res_dt <- merge(dt_x, dt_y' + all_args + by_args + ')\\n');
        }

    } else {
        var dts = getValue('cmb_bind_list');
        var fill = getValue('cmb_bind_fill') === 'TRUE' ? 'TRUE' : 'FALSE';
        var idcol = cleanStr(getValue('cmb_bind_idcol'));

        // Handle multiple datasets selected in the varslot
        var dt_arr = dts.split('\\n').filter(Boolean);
        var list_str = 'list(' + dt_arr.join(', ') + ')';
        var id_str = (idcol !== '') ? ', idcol = \"' + idcol + '\"' : '';

        echo('res_dt <- data.table::rbindlist(' + list_str + ', use.names = TRUE, fill = ' + fill + id_str + ')\\n');
    }

    // Native Data Preview
    echo('preview_data <- as.data.frame(head(res_dt, 50))\\n');
  "

  js_print_cmb <- "
    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header(\"data.table: Combine Data Summary\")\\n');

        var mode = getValue('cmb_mode');
        var op = (mode === 'join') ? 'Merge / Join (' + getValue('cmb_join_type') + ')' : 'Bind Rows (rbindlist)';

        echo('rk.print(paste(\"<b>Operation:</b>\", \"' + op + '\", \"| <b>Dimensions:</b>\", nrow(res_dt), \"rows x\", ncol(res_dt), \"cols\"))\\n');

        if (getValue('cmb_save.active')) {
            echo('rk.print(paste0(\"<b>Object saved as: </b><code>\", \"' + getValue('cmb_save') + '\", \"</code>\"))\\n');
        }
        echo('rk.print(\"<hr>\")\\n');
    }
  "

  # Assemble the Component
  comp_combine <- rk.plugin.component(
      "Joins & Bindings",
      xml = list(dialog = dialog_cmb, logic = logic_cmb),
      js = list(require = c("data.table"), globals = js_helpers, calculate = js_calc_cmb, printout = js_print_cmb),
      hierarchy = h_dt
  )



  # =========================================================================================
  # 4. BUILD SKELETON
  # =========================================================================================

  unlink("rk.data.table", recursive = TRUE)

  rk.plugin.skeleton(
    about = about_info,
    path = ".",
    xml = list(dialog = dialog_dt, logic = logic_dt),
    js = list(require = c("data.table"), globals = js_helpers, calculate = js_calc_dt, printout = js_print_dt),
    components = list(comp_io, comp_reshape, comp_combine),
    pluginmap = list(name = "Manipulate (DT[i,j,by])", hierarchy = h_dt),
    dependencies = dependencies_node,
    create = c("pmap", "xml", "js", "desc", "rkh"),
    overwrite = TRUE,
    load = TRUE
  )

  cat("\nPhase 1: 'rk.data.table' (Main Component) updated successfully.\n")
})
