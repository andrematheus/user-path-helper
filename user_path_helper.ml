open Core.Std

let expand_home path =
  let home = Sys.getenv_exn "HOME" in
  let path = String.substr_replace_all path ~pattern:"~" ~with_:home in
  String.substr_replace_all path ~pattern:"$HOME" ~with_:home

let all_user_paths () =
  let dir = List.fold ~init:(Sys.home_directory ()) ~f: Filename.concat ["Library"; "paths.d"] in
  let files = Sys.ls_dir dir in
  let paths = List.map files ~f:(fun s -> In_channel.with_file (Filename.concat dir s) ~f:In_channel.input_lines) in
  let paths = List.map ~f:(fun l -> List.map ~f:expand_home l) paths in
  ListLabels.flatten paths

let get_old_path () =
  let old_path = Sys.getenv "PATH" in
  match old_path with
  | Some p -> p
  | None -> ""

let remove_dups_in_other source other =
  let rec inner other acc =
    match other with
    | [] -> acc
    | h::t -> if List.exists source ~f:(fun s -> String.equal h s) then
        inner t acc
      else
        inner t (h::acc) in
  inner other []

let append_no_dups l1 l2 =
  l1 @ (remove_dups_in_other l1 l2)

let launchctl_output s = Printf.printf "launchctl setenv PATH %s\n" s
let export_output s = Printf.printf "PATH=%s; export PATH\n" s

let user_paths_setenv_cmd format =
    let old_path = get_old_path () in
    let components = String.split old_path ~on:':' in
    let user_paths = all_user_paths () in
    let merged = append_no_dups user_paths components in
    let path = String.concat ~sep:":" merged in
    format path

let spec =
  let open Command.Spec in
  empty
  +> flag "-f" (optional string) ~doc:"Output format, either launchctl or export. Defaults to launchctl"

let command =
  Command.basic
    ~summary: "Output user defined path variable"
    spec
    (fun output_format () ->
       match output_format with
       | Some "launchctl" | None -> user_paths_setenv_cmd launchctl_output
       | Some "export" -> user_paths_setenv_cmd export_output
       | Some x -> eprintf "'%s' is not a valid option.\n%!" x; exit 1)

let () =
  Command.run ~version:"1.0" command
