using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using vaultex.view.order.domain.order.Entities.OrderModel;

namespace vaultex.view.order.domain.order.Utilities
{
	public static class ValidatorUtils
	{
		public static List<string> ValidateOrder(List<Order> orders)
		{
			var errorList=new List<string>();
			foreach (var order in orders)
			{
				var validationctx = new ValidationContext(order);
				var validationResult = new List<ValidationResult>();
				var valid = Validator.TryValidateObject(order, validationctx, validationResult, true);
				if (!valid)
				{
					var errorMessages = validationResult.Select(x => x.ErrorMessage).ToList();
					errorList.AddRange(errorMessages);				

				}
			}
			return errorList;
		}
	}
}
