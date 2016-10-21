Pod::Spec.new do |s|

  s.name         = "NBDataBase"
  s.version      = "0.2.0"
  s.summary      = "an orm database."

  s.description  = <<-DESC
                   orm database.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC

  s.homepage     = "https://github.com/zhfeng20108/NBDataBase"

  s.license      = "MIT"

  s.author             = { "zhfeng" => "hhzhangfeng2008@163.com" }

  s.platform     = :ios, "5.0"

  s.source       = { :git => "https://github.com/zhfeng20108/NBDataBase.git", :tag => "0.2.0" }

  s.source_files  = "NBDataBase/*.{h,m}"

  s.library   = "sqlite3.0"

  s.requires_arc = true

  s.dependency "FMDB/SQLCipher"

end
