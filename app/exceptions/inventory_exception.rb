class InventoryException < StandardError

  def initialize(msg, exception_type = "insufficient_inventory")
    @exception_type = exception_type
    super(msg)
  end

end