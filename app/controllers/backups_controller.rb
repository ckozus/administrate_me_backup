require 'ostruct'

class BackupsController < ApplicationController
  #FIXME: Este controller solo deberá ser accedido por usuarios con el rol de administrador
  layout 'admin_layout'
  before_filter :s3_login_and_connect

  def index
    if AWS::S3::Base.connected?
      @objects = AWS::S3::Bucket.objects(@fu_conf[:s3_bucket]).map do |object|
        OpenStruct.new(:nombre_archivo => File.basename(object.path),
          :fecha => fecha_hora_objeto(object.path),
          :encoded_nombre_archivo => File.basename(object.path.gsub('.', '%2E')))
      end
    else
      @objects = []
    end
  end

  def show
    redirect_to AWS::S3::S3Object.url_for(URI.decode(params[:id]), @fu_conf[:s3_bucket], :expires_in => 1.minute)
  end

  def s3_login_and_connect
    fu_conf = YAML.load_file(File.join(RAILS_ROOT, 'config', 'backup_fu.yml'))
    @fu_conf = fu_conf[RAILS_ENV].symbolize_keys
    unless AWS::S3::Base.connected?
      AWS::S3::Base.establish_connection!(
        :access_key_id => @fu_conf[:aws_access_key_id],
        :secret_access_key => @fu_conf[:aws_secret_access_key]
      )
    end
    if !AWS::S3::Base.connected?
      flash.now[:error] = "Error al conectar a Amazon S3"
    end
  end

  protected

  def fecha_hora_objeto(path)
    path =~ Regexp.new("#{@fu_conf[:app_name]}_\\d{4}-\\d{2}-\\d{2}_(\\d+)_db")
    time = Time.at($1.to_i)
    time.strftime("%Y-%m-%d %H:%M")
  end

end
