# Used by scripts/xcodeproj. usage: add <path>... | remove <path>... | rename <old path> <new path>
# Paths are relative to the repo root. Keeps git and the Xcode project in sync.
require 'xcodeproj'
proj = Xcodeproj::Project.open('Magpie.xcodeproj')
target = proj.targets.find { |t| t.name == (ENV['TARGET'] || 'Magpie') }
cmd = ARGV.shift
def find_ref(proj, path)
  proj.files.find { |f| f.real_path.to_s.end_with?('/' + path) }
end
def group_for(proj, dir)
  group = proj.main_group
  dir.split('/').each do |comp|
    g = group.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.display_name == comp }
    g ||= group.new_group(comp, comp)
    group = g
  end
  group
end
case cmd
when 'add'
  ARGV.each do |path|
    next if find_ref(proj, path)
    ref = group_for(proj, File.dirname(path)).new_reference(File.basename(path))
    path.end_with?('.swift') ? target.add_file_references([ref]) : target.add_resources([ref])
    puts "added #{path}"
  end
when 'remove'
  ARGV.each do |path|
    ref = find_ref(proj, path)
    abort "not in project: #{path}" unless ref
    ref.build_files.each { |bf| bf.remove_from_project }
    ref.remove_from_project
    system('git', 'rm', '-q', path) || File.delete(path)
    puts "removed #{path}"
  end
when 'rename'
  old, new = ARGV
  ref = find_ref(proj, old)
  abort "not in project: #{old}" unless ref
  abort "rename across folders not supported" unless File.dirname(old) == File.dirname(new)
  system('git', 'mv', old, new) or abort "git mv failed"
  ref.path = File.basename(new)
  ref.name = nil
  puts "renamed #{old} -> #{new}"
end
proj.save
